require 'csv'
require 'market/market'
module ClusteringModule
  class Evaluator
    def initialize(clusters: Cluster.all,
                   startDate: Time.now - 1.month,
                   endDate: Time.now,
                   interval: 1.week,
                   outputFile: 'res.csv')
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

        csv << ["startDate", "endDate"] + @clusters.map{|c| c.name}

        (@startDate.to_i .. @endDate.to_i).step(@interval.to_i) do |secs|
          sd = Time.at(secs)
          ed = sd + @interval
          csv << [sd,ed] + @clusters.map{|c| get_penalty_reduction(c, sd, ed)}
        end
      end
    end

    def get_penalty_reduction(cluster, startDate, endDate)
      stats = Market::Calculator.new(prosumers: cluster.prosumers,
                                     startDate: startDate,
                                     endDate: endDate)
                  .calcCosts[:dissagrgated]
                  .select { |d| d[:id] < 0 }
                  .map { |d| [d[:id], d.dup.update(penalty: d[:real] - d[:ideal])] }


      puts JSON.pretty_generate stats
      ( ( stats[-2][1][:penalty] - stats[-1][1][:penalty] ) / stats[-2][1][:penalty] * 100) if stats[-2][1][:penalty] > 0
    end


  end
end