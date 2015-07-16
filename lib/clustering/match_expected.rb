module CLusteringModule
  class TargetMatcher
    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.day,
                   endDate: Time.now,
                   interval: 1.hour)

      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
    end

    def real_consumption
      result = Hash[DataPoint.where(prosumer: clusters.map{|tc| tc.prosumers}.flatten,
                                    interval: 2,
                                    timestamp: ts)
                        .map do |dp|
                      [dp.prosumer_id, dp.consumption]
                    end]
      puts "result: #{result}"
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
        @real_consumption = options[:real_consumption]

      end

      def fitness
        return @fitness if @fitness

        total_consumption = @targets.map {|t| 0}
        @data.each_with_index do |d, i|
          if d == 1
            total_consumption.zip(@real_consumption[@prosumers[i].id]).map do |t,r|
              t + r
            end
          end
        end

        error += total_consumption.zip(@targets).sum do |r,t|
          (r - t).abs
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

        return DynamicChromosome.new(spawn, a.options)
      end

      def self.seed(options)

        #  puts "I am in the corrext seed function, options: #{options}"
        data_size = options[:prosumers].length

        seed = []
        0.upto(data_size-1) do
          seed << rand(2)
        end
        #  puts "seed options: #{options[:errors].length}"
        return DynamicChromosome.new(seed, options)
      end

    end
  end
end