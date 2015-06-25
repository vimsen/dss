require 'csv'
require 'market/market'
require "clustering/dynamic_chromosome"
require "clustering/ai4r_modifications"

module ClusteringModule
  class Evaluator
    def initialize(clusters: Cluster.all,
                   startDate: Time.now - 1.month,
                   endDate: Time.now,
                   interval: 1.week,
                   outputFile: 'res.csv',
                   adaptive: false)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
    end

    def evaluate

      CSV.open(@outputFile, "w", {:col_sep => "\t"}) do |csv|

        csv << ["week"] + @clusters.map{|c| c.name}

        (@startDate.to_i .. @endDate.to_i).step(@interval.to_i).with_index do |secs, i|
          sd = Time.at(secs)
          ed = sd + @interval
          csv << [ i ] + all_penalty_reductions(@clusters, sd, ed)
        end
      end
    end

    def all_penalty_reductions(clusters, sd, ed)
      if @adaptive
        get_dynamic_getnalty_reduction(@clusters, sd, ed)
      else
        @clusters.map{|c| get_penalty_reduction(c.prosumers, sd, ed)}
      end
    end


    def get_stats(prosumers, startDate, endDate)
      Market::Calculator.new(prosumers: prosumers,
                             startDate: startDate,
                             endDate: endDate)
          .calcCosts[:dissagrgated]
          .select { |d| d[:id] < 0 }
          .map { |d| [d[:id], d.dup.update(penalty: d[:real] - d[:ideal])] }
    end


    def get_penalty_reduction(prosumers, startDate, endDate)
      stats = get_stats(prosumers, startDate, endDate)
#       puts JSON.pretty_generate stats
      ( ( stats[-2][1][:penalty] - stats[-1][1][:penalty] ) / stats[-2][1][:penalty] * 100) if stats[-2][1][:penalty] > 0
    end

    def get_targets(clusters, ts)
      clusters.map do |c, i|
        DataPoint.where(prosumer: c.prosumers,
                        interval: 2,
                        f_timestamp: ts).sum(:f_consumption)
      end
    end

    def real_consumption(clusters, ts)
      result = Hash[DataPoint.where(prosumer: clusters.map{|tc| tc.prosumers}.flatten,
                           interval: 2,
                           timestamp: ts)
               .map do |dp|
                      [dp.prosumer_id, dp.consumption]
                    end]
      puts "result: #{result}"
      result
    end

    def get_dynamic_getnalty_reduction(clusters, sd, ed)
      # penalties_before = Hash[clusters.map.with_index do |cl, i|
      #               [i, get_stats(cl.prosumers, sd, ed)[-2][1][:penalty]]
      #             end]

      (sd.beginning_of_hour.to_i ..
          (ed - 1.hour).beginning_of_hour.to_i).step(1.hour).map do |t|
        ts = Time.at(t)
        search = Ai4r::GeneticAlgorithm::GeneticSearchWithOptions.new(
            200, 100, prosumers: clusters.map{|tc| tc.prosumers}.flatten,
            kappa: clusters.count,
            penalty_violation: 0.3, penalty_satisfaction: 0.2,
            class: Ai4r::GeneticAlgorithm::DynamicChromosome,
            targets: get_targets(clusters, ts),
            real_consumption: real_consumption(clusters, ts)
        )
        search.run

      end

    end

  end
end
