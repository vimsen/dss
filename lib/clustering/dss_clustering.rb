
require "clustering/ai4r_modifications"
require 'csv'

module ClusteringModule


  class GeneticErrorClustering

    attr_accessor :last_run_stats
    
=begin
    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.week,
                   endDate: Time.now,
                   algorithm: Ai4r::GeneticAlgorithm::StaticChromosome,
                   penalty_violation: 0.3, penalty_satisfaction: 0.2,
                   population_size: 200, generations: 100)
    
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    
      forecasts = Hash[DataPoint.where(prosumer: @prosumers,
                                        interval: 2,
                                        f_timestamp: @startDate .. @endDate)
                           .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
                           .map do |dp|
        [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_prosumption]
      end]

      real = Hash[DataPoint.where(prosumer: @prosumers,
                                   interval: 2,
                                   timestamp: @startDate .. @endDate)
                      .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
                      .map do |dp|
        [[dp.prosumer_id, dp.timestamp.to_i], dp.prosumption]
      end]
      @errors = Hash[real.map do |k, v|
                       [k, (v || 0) - (forecasts[k] || 0)]
                     end]
    end
=end

  
    def prepare_input_dataset(instance_id , kappa = 5)
      
      @lastRunSTats = {start_run: Time.now}

      params = [@population_size, @generations, {errors: @errors, prosumer_ids: @prosumers.map{|p| p.id}, kappa: kappa,
                penalty_violation: @penalty_violation,
                penalty_satisfaction: @penalty_satisfaction,
                class: @algorithm,
                stats: @lastRunSTats}]

      filename = Rails.root.join("storage/"+instance_id.to_s+"_input_dataset.json")
      File.open(filename, "w") do |file|
        file.puts JSON.pretty_generate params
      end
    
    end

  end

end
