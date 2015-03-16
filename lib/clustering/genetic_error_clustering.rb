module ClussteringModule
  class GeneticErrorClustering
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


    def run(kappa = 5)


      




    end

  end
end