require "clustering/ai4r_modifications"


module ClusteringModule


  class GeneticErrorClustering
    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.week,
                   endDate: Time.now,
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

      puts "Beginning genetic search, please wait... "
      search = Ai4r::GeneticAlgorithm::GeneticSearch.new(
          200, 100, errors: @errors, prosumers: @prosumers, kappa: kappa,
          penalty_violation: @penalty_violation,
          penalty_satisfaction: @penalty_satisfaction)
      best = search.run
      puts "FITNESS #{best.fitness} CLUSTERS: "+
               "#{best.data.zip(@prosumers).map {|c,p| [p.id, c]}}"

      result = []
      best.data.each_with_index do |g, i|
        result[g] ||= TempCluster.new(name: "Gen #{g}",
                                      description: "Genetic clustering #{g}")
        result[g].prosumers.push Prosumer.find(@prosumers[i])
      end
      result.reject{ |c| c.nil? || c.prosumers.nil?}

    end

  end
end