require "clustering/ai4r_modifications"
require 'csv'

module ClusteringModule


  class GeneticErrorClustering

    attr_accessor :last_run_stats
    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.week,
                   endDate: Time.now,
                   algorithm: Ai4r::GeneticAlgorithm::StaticChromosome,
                   penalty_violation: 0.3, penalty_satisfaction: 0.2)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
      forecasts = Hash[DataPoint.where(prosumer: @prosumers,
                                        interval: 2,
                                        f_timestamp: @startDate .. @endDate)
                            .map do |dp|
                          [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                        end]
      real = Hash[DataPoint.where(prosumer: @prosumers,
                                   interval: 2,
                                   timestamp: @startDate .. @endDate)
                       .map do |dp|
                     [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
                   end]
      @errors = Hash[real.map do |k, v|
                       [k, v - (forecasts[k] || 0)]
                     end]
    end

    def run(kappa = 5)
      @lastRunSTats = {start_run: Time.now}

      puts "Beginning genetic search, please wait... "
      search = Ai4r::GeneticAlgorithm::GeneticSearchWithOptions.new(
          200, 100, errors: @errors, prosumers: @prosumers, kappa: kappa,
          penalty_violation: @penalty_violation,
          penalty_satisfaction: @penalty_satisfaction,
          class: @algorithm,
          stats: @lastRunSTats)
      best = search.run
      puts "FITNESS #{best.fitness} CLUSTERS: "+
               "#{best.data.zip(@prosumers).map {|c,p| [p.id, c]}}"


      result = []
      best.data.each_with_index do |g, i|
        result[g] ||= []
        result[g].push i
      end
      result.reject{ |c| c.nil? || c.empty?}

      result.map.with_index do |cl, i|
        TempCluster.new(name: "Genetic #{i}",
                        description: "Genetic clustering #{i}",
                        prosumers: cl.map { |p| @prosumers[p]})
      end
    end

    def dump_stats(file)
      CSV.open(file, "w", {:col_sep => "\t"}) do |csv|
        csv << ["generation", "time", "fitness"]
        @lastRunSTats[:gen].each_with_index do |e, i|
          csv << [i, e[:time], e[:fitness]]
        end
      end
    end
  end
end
