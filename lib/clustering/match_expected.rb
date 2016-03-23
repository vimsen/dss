
require "clustering/ai4r_modifications"

module ClusteringModule
  class TargetMatcher

    attr_accessor :targets
    attr_accessor :prosumers

    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.day,
                   endDate: Time.now,
                   interval: 1.hour,
                   targets: 25.times.map {|ts| 0},
                   rb_channel: nil
      )

      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end

      raise "Wrong targets size" if @targets.length != timestamps.length

      @prosumers = reject_zeros(@prosumers, real_prosumption)

      if ! @rb_channel.nil?
        Rails.logger.debug "Connecting to channel..."
        begin
          bunny_channel = $bunny.create_channel
          @x = bunny_channel.fanout(@rb_channel)
        rescue Bunny::Exception # Don't block if channel can't be fanned out
          Rails.logger.debug "Can't fanout channel #{channel}"
          @x = nil
        end
      end

    end

    def run

      search = Ai4r::GeneticAlgorithm::GeneticSearchWithOptions.new(
          200, 100, prosumers: @prosumers,
          class: Ai4r::GeneticAlgorithm::MatchChromosome,
          targets: @targets,
          real_prosumption: real_prosumption,
          rb_channel: @x
      )

      best = search.run

      {
          prosumers: best.data.zip(@prosumers).select do |ch, pr|
            ch == 1
          end.map do |ch, pr|
            Prosumer.find(pr.id)
          end.sort_by{|p| p.name},
          consumption: timestamps.map{|ts| ts.to_i * 1000 }.zip(best.result)
      }

    end

    def reject_zeros(prosumers, rc)
      prosumers.reject do |p|
        rc[p.id].max == 0
      end
    end

    def timestamps
      return @timestamps if @timestamps
      @timestamps = (normalise(@startDate).to_i .. normalise(@endDate).to_i).step(@interval).map do |ts|
        Time.at(ts)
      end
    end

    def normalise(timestamp)
      case @interval
        when 1.hour
          timestamp.beginning_of_hour
        when 1.day
          timestamp.beginning_of_day
        else
          raise "Wrong interval"
      end


    end

    def real_prosumption
      result = Hash[@prosumers.map {|p| [p.id, timestamps.map{|ts| 0}]}]

      timestamps.map do |ts|
        DataPoint.where(prosumer: @prosumers,
                        interval: 2,
                        timestamp: ts).select(:prosumer_id, 'COALESCE(consumption,0) - COALESCE(production,0) as prosumption')
            .map do |dp|
          result[dp.prosumer_id][timestamps.index(ts)] = dp[:prosumption]

          [dp.prosumer_id, dp[:prosumption]]
        end
      end
      result
    end

  end
end




module Ai4r
  module GeneticAlgorithm
    class MatchChromosome < Chromosome

      attr_accessor :data
      attr_accessor :normalized_fitness
      attr_accessor :options

      def initialize(data, options)
        if options.nil?
          puts Thread.current.backtrace.join("\n")
          Thread.exit
        end
        @data = data
        @options = options
        @targets = options[:targets]
        @prosumers = options[:prosumers]
        @real_prosumption = options[:real_prosumption]

      end

      def result
        total_consumption = @targets.map {|t| 0}
        @data.each_with_index do |d, i|
          #   puts "d= #{d}, i=#{i}"

          if d == 1
            total_consumption = total_consumption.zip(@real_prosumption[@prosumers[i].id]).map do |t,r|
              t + r
            end
          end
        end
        total_consumption
      end

      def fitness
        return @fitness if @fitness

        total_consumption = @targets.map {|t| 0}
        @data.each_with_index do |d, i|
       #   puts "d= #{d}, i=#{i}"

          if d == 1
            total_consumption = total_consumption.zip(@real_prosumption[@prosumers[i].id]).map do |t,r|
              t + r
            end
          end
        end

        # puts "TOTAL: #{total_consumption}, TARGET: #{@targets}"

        error = total_consumption.zip(@targets).sum do |r, t|
          # puts "r= #{r}, t= #{t}"
          (r - t) ** 2
        end

        return -error
      end

      def self.mutate(chromosome)
        if chromosome.normalized_fitness && rand < ((1 - chromosome.normalized_fitness) * 0.3)
          data = chromosome.data
          index = rand(data.length-1)
          data[index], data[index+1] = data[index+1], data[index]
          chromosome.data = data
          @fitness = nil
        end
      end

      def self.reproduce(a, b)

        #Two point crossover
        current = rand(2)
        point1 = rand(a.data.length)
        point2 = rand(a.data.length)
#        puts "reproduce, #{point1}, #{point2}"
        spawn = a.data.zip(b.data).map.with_index do |g, i|
          current = 1 - current if (i == point1) ^ (i == point2)
          #    puts "#{g[0]},#{g[1]},#{i},#{current}, #{g[current]}"
          g[current]
        end


        # The following is uniform crossover
        # spawn = a.data.zip(b.data).map do |g1 ,g2|
        #   rand(2) > 0 ? g1 : g2
        # end

        return self.new(spawn, a.options)
      end

      def self.seed(options)

        #  puts "I am in the corrext seed function, options: #{options}"
        data_size = options[:prosumers].length

        seed = []
        0.upto(data_size-1) do
          seed << rand(2)
        end
        #  puts "seed options: #{options[:errors].length}"
        return self.new(seed, options)
      end

    end
  end
end