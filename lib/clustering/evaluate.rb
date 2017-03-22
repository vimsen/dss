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
                   outputFile: 'res_',
                   adaptive: false,
                   runs: 2)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
    end

    def evaluate

      @runs.times do |j|
        # f3 = CSV.open(@outputFile + j.to_s + ".csv", "w", {:col_sep => "\t"})
        # f1 = CSV.open(@outputFile + j.to_s + "_before.csv", "w", {:col_sep => "\t"})
        # f2 = CSV.open(@outputFile + j.to_s + "_after.csv", "w", {:col_sep => "\t"})

        # CSV.open(@outputFile + j.to_s + "_after.csv", "w", {:col_sep => "\t"}) do |csv2|

        CSV.open(@outputFile + j.to_s + "_before.csv", "w", {:col_sep => "\t"}) do |csv1|
          CSV.open(@outputFile + j.to_s + "_after.csv", "w", {:col_sep => "\t"}) do |csv2|
            CSV.open(@outputFile + j.to_s + ".csv", "w", {:col_sep => "\t"}) do |csv3|
              csv1 << ["week"] + @clusters.map{|c| c.name}
              csv2 << ["week"] + @clusters.map{|c| c.name}
              csv3 << ["week"] + @clusters.map{|c| c.name}
              (@startDate.to_i .. @endDate.to_i).step(@interval.to_i).with_index do |secs, i|
                sd = Time.at(secs)
                ed = sd + @interval
                penalties = all_penalty_reductions(@clusters, sd, ed)
                puts "Penalties: #{penalties}"
                csv1 << [ i ] + penalties.map{|p| p[0]}
                csv2 << [ i ] + penalties.map{|p| p[1]}
                csv3 << [ i ] + penalties.map{|p| p[2]}
                csv1.flush
                csv2.flush
                csv3.flush
              end
            end
          end
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
      Hash[
          Market::Calculator.new(prosumers: prosumers,
                                 startDate: startDate,
                                 endDate: endDate)
              .calcCosts[:disaggregated]
              .select { |d| d[:id] < 0 }
              .map { |d| [d[:id], d.dup.update(penalty: d[:real] - d[:ideal])] }
      ]
    end

    def get_penalty(prosumers, timestamp, target)
      Market::Calculator.new(prosumers: prosumers,
                             startDate: timestamp,
                             endDate: timestamp)
          .penalty_for_single(target)
    end


    def get_penalty_reduction(prosumers, startDate, endDate)
      stats = get_stats(prosumers, startDate, endDate)
#       puts JSON.pretty_generate stats

#       [stats[-2][1][:penalty], stats[-1][1][:penalty]]
      [
          stats[-1][:penalty],
          stats[-2][:penalty],
          stats[-1][:penalty] > 0 ?
              ((stats[-1][:penalty] - stats[-2][:penalty]) /
                  stats[-1][:penalty] * 100) :
              "NaN"
      ]
    end

    def get_targets(clusters, ts)
      result = clusters.map do |c, i|
        DataPoint.where(prosumer: c.prosumers.map{|p| p.id},
                        interval: 2,
                        f_timestamp: ts)
            .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
            .sum(:f_prosumption)
      end
      puts "TARGET first: #{result}"
      result
    end

    def get_real_before_reclustering(clusters, ts)
      result = clusters.map do |c, i|
        DataPoint.where(prosumer: c.prosumers.map{|p| p.id},
                        interval: 2,
                        timestamp: ts)
            .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
            .sum(:prosumption)
      end
      puts "REAL BEFORE first: #{result}"
      result
    end


    def get_imballance_before(clusters, ts)
      target = get_targets(clusters, ts)
      before = get_real_before_reclustering(clusters, ts)

      before.zip(target).map do |b,t|
        b - t
      end
    end

    def real_consumption(clusters, ts)
      result = Hash[DataPoint.where(prosumer: clusters.map{|tc| tc.prosumers}.flatten,
                           interval: 2,
                           timestamp: ts)
                        .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
                        .map do |dp|
        [dp.prosumer_id, dp.prosumption]
      end]
      puts "result: #{result}"
      result
    end

    def get_dynamic_getnalty_reduction(clusters, sd, ed)

      all_prosumers = clusters.map{|tc| tc.prosumers}.flatten

      penalties_before = clusters.map do |cl|
                     get_stats(cl.prosumers, sd, ed)[-1][:penalty]
                   end

      puts JSON.pretty_generate penalties_before

      penalties_after = (((sd.beginning_of_hour.to_i ..
          (ed - 1.hour).beginning_of_hour.to_i).step(1.hour).map do |t|
        ts = Time.at(t)

        targets = get_targets(clusters, ts)

        search = Ai4r::GeneticAlgorithm::GeneticSearchWithOptions.new(
            200, 100, prosumers: all_prosumers,
            kappa: clusters.count,
            penalty_violation: 0.3, penalty_satisfaction: 0.2,
            class: Ai4r::GeneticAlgorithm::DynamicChromosome,
            targets: targets,
            initial_imballance: get_imballance_before(clusters, ts),
            real_consumption: real_consumption(clusters, ts)
        )

        best = search.run

        puts "NEW CLUSTERING: #{best.data.zip(all_prosumers).map {|c,p| [p.id, c]}}"

        result = penalties_before.map{|k| []}
        best.data.each_with_index do |g, i|
#           result[g] ||= []
          result[g].push Prosumer.find(all_prosumers[i])
        end
        puts "FITNESS: #{best.fitness}"
        result.map.with_index do |c, i|
          puts "Cluster: #{c.map{|p| p.id}}"
          c.length > 0 ? get_penalty(c, ts, targets[i]) : 0
        end
      end).transpose.map{|k| k.sum})
      puts "audit: #{penalties_before}, #{penalties_after}"
      # penalties_before.zip(penalties_after).map{|b,a| [b, a, (b-a)/b * 100]}
      penalties_before.zip(penalties_after).map{|b,a| [b, a, a > 0 ? (b-a)/b * 100 : "NaN"]}
    end

  end
end
