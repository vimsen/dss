module ClusteringModule


  class GeneticErrorClustering
    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.week,
                   endDate: Time.now)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
      @forecasts = Hash[DataPoint.where(prosumer: @prosumers,
                                        interval: 2,
                                        f_timestamp: @startDate .. @endDate)
                            .map do |dp|
                          [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                        end]
      @real =  Hash[DataPoint.where(prosumer: @prosumers,
                                    interval: 2,
                                    timestamp: @startDate .. @endDate)
                        .map do |dp|
                      [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
                    end]
      @errors = Hash[@real.map do |k,v|
                       [ k, v - (@forecasts[k] || 0)]
                     end]
    end

    def errors
      @errors
    end

    def run(kappa = 5)
      p = Darwinning::Population.new(
          organism: MyOrganism, population_size: 10,
          fitness_goal: 0, generations_limit: 100
      )
      p.evolve!

      p.best_member.nice_print

    end

    class MyOrganism < Darwinning::Organism

      @name = "Test"

      @gemes = Prosumer.all.map.with_index do |p,i|
        Darwinning::Gene.new(name: "#{i}th digit", value_range: (0..4))
      end

      def fitness

        clusters = []
        genotypes.each_with_index do |v, i|
          clusters[v] ||= []
          clusters[v].push i
        end

        puts "Errors", base_line_penalties

        # Try to get the sum of the 3 digits to add up to 15
        (genotypes.inject{ |sum, x| sum + x } - 15).abs
      end

      def base_line_penalties
        GeneticErrorClustering.errors.sum do |k,v|
          v.abs
        end
      end

    end

  end
end