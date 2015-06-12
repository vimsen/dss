require "clustering/ai4r_modifications"

module ClusteringModule

  class Dynamic
    def initialize(clustering, date: Date.today)
      @clustering = clustering
      @date = date

      @forecasts = Hash[DataPoint.where(prosumer: @clustering.temp_clusters.map{|tc| tc.prosumers}.flatten,
                                       interval: 2,
                                       f_timestamp: @date.midnight .. (@date + 1.day).midnight)
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                       end]

      cluster_of = @clustering.temp_clusters.map do |tc|
        Hash[tc.prosumers.map do |p|
          [p.id, tc.id]
        end]
      end.reduce &:merge

      @forecasts_per_cluster = @forecasts.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end

      real_per_hour = Hash[DataPoint.where(prosumer: @clustering.temp_clusters.map{|tc| tc.prosumers}.flatten,
                                  interval: 2,
                                  timestamp: @date.midnight .. (@date + 1.day).midnight)
                      .map do |dp|
                    [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
                  end]

      @real_per_hour_cluster = real_per_hour.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end

      @real_per_quarter = Hash[DataPoint.where(prosumer: @clustering.temp_clusters.map{|tc| tc.prosumers}.flatten,
                                           interval: 1,
                                           timestamp: @date.midnight .. (@date + 1.day).midnight)
                               .map do |dp|
                             [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
                           end]

      @real_per_quarter_cluster = @real_per_quarter.each_with_object({}) do |((pr_id, timestamp), value), h|
        h[[cluster_of[pr_id],timestamp]] ||= 0
        h[[cluster_of[pr_id],timestamp]] += value
      end


      puts @forecasts_per_cluster, @real_per_hour_cluster, @real_per_quarter_cluster

=begin

      forecasts = Hash[DataPoint.where(prosumer: @prosumers,
                                       interval: 2,
                                       f_timestamp: day_ahead_date.midnight .. @date.midnight)
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
=end

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
          prosumers: @clustering.temp_clusters.map{|tc| tc.prosumers}.flatten,
          kappa: @clustering.temp_clusters.count,
          penalty_violation: 0.3, penalty_satisfaction: 0.2
      )

      best = search.run
    end


    def adapt_hourly_block(timestamp)
      (timestatmp - 3600 .. timestamp).step(900).map do ||
    end

  end

end