module ClusteringModule
  class ForecastErrorClustering

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
                            .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
                            .map do |dp|
        [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_prosumption]
      end]

      @real =  Hash[DataPoint.where(prosumer: @prosumers,
                                   interval: 2,
                                   timestamp: @startDate .. @endDate)
                        .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
                        .map do |dp|
        [[dp.prosumer_id, dp.timestamp.to_i], dp.prosumption]
      end]



      @errors = Hash[@real.map do |k,v|
                      [ k, v - (@forecasts[k] || 0)]
                     end]
    end

    def centroid(prosumers)

      procs = Hash[prosumers.map do |p|
                     [p.id, true]
                   end]

      @errors.select{|key,value| procs[key[0]]}.inject({}) do |res, (key,value)|
        res[key[1]] ||= 0
        res[key[1]] += value
        res
      end
    end

    def distance(centroid, prosumer)
      centroid.inject(0) do |res, (key,value)|
        res + (value - (@errors[[prosumer.id, key]] || 0)).abs
      end
    end

    def find_closest(centroids, prosumer)
      centroids.min_by do |k,v|
        distance(v, prosumer)
      end
    end

    def closest_or_new(centroids, prosumer)

      candidates = centroids.select do |k,v|
        distance(v, Prosumer.new) > distance(v, prosumer)
      end

      Rails.logger.debug "Number of cluster candidates: #{candidates.count}"

      return [-1, 0] if candidates.empty?

      candidates.max_by do |k,v|
        Rails.logger.debug "index #{k}"
        Rails.logger.debug distance(v, Prosumer.new)
        Rails.logger.debug distance(v, prosumer)
        distance(v, Prosumer.new) - distance(v, prosumer)
      end
    end

    def run(kappa = 5)
      remaining_prosumers = @prosumers.sort_by{|p| - centroid([p]).sum{|k,v| v.abs}}
      centroids = {}
      result = []

      i = 0;
      remaining_prosumers.each do |p|

        best = closest_or_new(centroids, p)[0]
        if best < 0
          cl = TempCluster.new(
                          name: "Est: #{i}",
                          description: "Estimation Error clustering")
          result[i] = cl
          best = i
          i += 1
        end
        result[best].prosumers.push p
        centroids[best] = centroid(result[best].prosumers)
      end

      result
    end

  end
end