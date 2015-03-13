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
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                       end]

      @real =  Hash[DataPoint.where(prosumer: @prosumers,
                                   interval: 2,
                                   timestamp: @startDate .. @endDate)
                       .map do |dp|
                     [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
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
        res[key] ||= 0
        res[key] += value
        res
      end
    end

    def run(kappa = 5)
      result = @prosumers.sample(kappa).map.with_index do |p, i|
        cl = TempCluster.new(name: "Est: #{i}",
                             description: "Estimation Error clustering")
        cl.prosumers.push p
        cl
      end

      result
    end

  end
end