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
      @@errors = Hash[@real.map do |k,v|
                       [ k, v - (@forecasts[k] || 0)]
                     end]
    end

    def self.errors
      ## This is a SEVERE bug. No concurrency allowed
      @@errors
    end

    def run(kappa = 5)
      p = Darwinning::Population.new(
          organism: MyOrganism, population_size: 10,
          fitness_goal: 0, generations_limit: 2
      )
      p.evolve!

      result = []
      p.best_member.genotypes.each_with_index do |g, i|
        result[g] ||= TempCluster.new(name: "Gen #{g}",
                                      description: "Genetic clustering #{g}")

        result[g].prosumers.push Prosumer.find(ClusteringModule::GeneticErrorClustering::MyOrganism.genes[i].name)
      end

      result.reject{ |c| c.nil? || c.prosumers.nil?}
    end

    class MyOrganism < Darwinning::Organism

      @name = "Test"

      @genes = ::Prosumer.all.map.with_index do |p,i|
        Darwinning::Gene.new(name: p.id, value_range: (0..4))
      end


      #def initialize

       # @test = "Hello"
      #end

      def fitness

        clusters = []
       # puts "gen",genotypes.size
        genotypes.each_with_index do |v, i|
          clusters[self.class.genes[i].name] = v
        end

        puts "Errors", base_line_penalties, clustered_penalties(clusters)

        # Try to get the sum of the 3 digits to add up to 15
        # (genotypes.inject(0){ |sum, x| sum + x } - 15).abs
        clustered_penalties(clusters)
      end

      def base_line_penalties
        @@base_line_penalties ||= GeneticErrorClustering.errors.sum do |k,v|
          puts "called"
          v.abs
        end
      end

      def clustered_penalties(clusters)
        cl_errors = {}
        GeneticErrorClustering.errors.each do |k,v|
          cl_errors[[clusters[k[0]], k[1]]] ||= 0
          cl_errors[[clusters[k[0]], k[1]]] += v
        end

        cl_errors.sum do |k,v|
          v.abs
        end
      end

    end

  end
end