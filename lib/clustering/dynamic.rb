require "clustering/ai4r_modifications"

module ClusteringModule

  class Dynamic
    def initialize(clusters, date: Date.today)
      @clusters = clusters
      @date = date

      @forecasts = Hash[DataPoint.where(prosumer: @clusters.map{|tc| tc.prosumers}.flatten,
                                       interval: 2,
                                       f_timestamp: @date.midnight .. (@date + 1.day).midnight)
                            .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
                            .map do |dp|
        [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_prosumption]
      end]

      cluster_of = @clusters.map do |tc|
        Hash[tc.prosumers.map do |p|
          [p.id, tc.id]
        end]
      end.reduce &:merge

      @forecasts_per_cluster = @forecasts.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end

      real_per_hour = Hash[DataPoint.where(prosumer: @clusters.map{|tc| tc.prosumers}.flatten,
                                  interval: 2,
                                  timestamp: @date.midnight .. (@date + 1.day).midnight)
                               .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
                               .map do |dp|
        [[dp.prosumer_id, dp.timestamp.to_i], dp.prosumption]
      end]

      @real_per_hour_cluster = real_per_hour.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end

      @real_per_quarter = Hash[DataPoint.where(prosumer: @clusters.map{|tc| tc.prosumers}.flatten,
                                           interval: 1,
                                           timestamp: @date.midnight .. (@date + 1.day).midnight)
                                   .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
                                   .map do |dp|
        [[dp.prosumer_id, dp.timestamp.to_i], dp.prosumption]
      end]

      @real_per_quarter_cluster = @real_per_quarter.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end


      puts @forecasts_per_cluster, @real_per_hour_cluster, @real_per_quarter_cluster

    end

    def validate_real
      @real_per_hour_cluster.each do |(cl_id, timestamp), value|
        s = (0..3).sum do |n|
          puts n
          @real_per_quarter_cluster[[cl_id, timestamp - 900 * n]] || 0
        end
        puts "#{value}, #{s}"
      end

    end

    def errors_before(cl_id)

      (@date.midnight.to_i .. (@date + 1.day).midnight.to_i).step(3600).map do |ts|
        puts "#{Time.at(ts)}: #{100 * (@real_per_hour_cluster[[cl_id, ts]] -
                 @forecasts_per_cluster[[cl_id, ts]])/@real_per_hour_cluster[[cl_id, ts]]}" if !@real_per_hour_cluster[[cl_id, ts]].nil? && !@forecasts_per_cluster[[cl_id, ts]].nil? && @real_per_hour_cluster[[cl_id, ts]] > 0
      end

    end

    def adaptation(timestamp_now, timestamp_contract)
      quarters_left = (timestamp_contract - timestamp_now) / 900
      estimates_factor = 4.0 / (4 - quarters_left)

      real_time_forecasts = Hash[@real_per_quarter.map do |(pr_id, ts), value|
                                   [[pr_id, timestamp_contract], estimates_factor * value]
                                 end]

      f_errors = Hash[real_time_forecasts.map do |k,v|
                        puts "#{v}, #{@forecasts[k]}, #{v - (@forecasts[k] || 0)}"
                        [k, v - (@forecasts[k] || 0)]
                      end]

      search = Ai4r::GeneticAlgorithm::GeneticSearch.new(
          200, 100, errors: f_errors,
          prosumers: @clusters.map{|tc| tc.prosumers}.flatten,
          kappa: @clusters.count,
          penalty_violation: 0.3, penalty_satisfaction: 0.2
      )

      best = process_result(@clusters.map{|tc| tc.prosumers}.flatten, search.run)
    end

    def process_result(prosumers, chromosome)
      hash = prosumers.zip(chromosome.data).inject({}) do |h, (p, c)|
        h[c] ||= []
        h[c].push(p)
        h
      end
    end

    def adapt_hourly_block(timestamp)
      (timestamp - 2700 .. timestamp).step(900).map do |ts|
        res = adaptation(ts, timestamp)
        [Time.at(ts), res]
      end
    end

    def adapt_daily
      (@date.midnight.to_i .. ((@date + 1).midnight - 1.hour).to_i).step(1.hour).each do |ts|
        adaptation(ts, ts).map do |cl_id, prosumers |

        end

      end
    end
  end

end