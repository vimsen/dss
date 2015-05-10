module Market

  class Calculator

    def initialize(prosumers: nil, startDate: nil, endDate: nil,
                   penalty_violation: 0.3, penalty_satisfaction: 0.2)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end
    end

    def calcCosts
      forecast_cache = {}
      price_cache = {}
      aggr_costs = {id: -2, name: 'aggr.', forecast: 0, ideal: 0, real: 0}
      ActiveRecord::Base.connection_pool.with_connection do
        {
            plot: [
                {
                    label: "forecast",
                    data: forecast.map do |f|
                      forecast_cache[f.f_timestamp.to_i] = f.fc
                      price_cache[f.f_timestamp.to_i] = forecast_price(f.f_timestamp, f.timestamp)
                     #  puts "timestamp: #{f.f_timestamp}, price: #{forecast_price(f.f_timestamp, f.timestamp)}"
                      aggr_costs[:forecast] += f.fc * price_cache[f.f_timestamp.to_i]
                      [f.f_timestamp.to_i * 1000, f.fc * price_cache[f.f_timestamp.to_i]]
                    end
                }, {
                    label: "ideal",
                    data: real.map do |f|
                      aggr_costs[:ideal] += f.consumption * real_price(f.timestamp)
                      [f.timestamp.to_i * 1000, f.consumption * real_price(f.timestamp)]
                    end
                },  {
                    label: "individual",
                    data: sum_cost
                },{
                    label: "cluster",
                    data: real.map do |f|
                      aggr_costs[:real] += real_cost(f, forecast_cache, {f.timestamp.to_i => real_price(f.timestamp)})
                      [f.timestamp.to_i * 1000, real_cost(f, forecast_cache, price_cache)]
                    end
                }
            ],
            dissagrgated: calcDiss + [aggr_costs]
        }
      end
    end

    def calcDiss
      fore_cost = {}
      ideal_cost = {}
      real_cost = {}
      forecast_cache = {}
      price_cache = {}
      total_costs = {id: -1, name: :sum, forecast: 0, ideal: 0, real: 0}
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      f_timestamp: @startDate .. @endDate).each do |dp|
        forecast_cache[dp.prosumer_id] ||= {}
        forecast_cache[dp.prosumer_id][dp.f_timestamp.to_i] = dp.f_consumption
        price_cache ||= {}
        price_cache[dp.f_timestamp.to_i] = forecast_price(dp.f_timestamp, dp.timestamp)
        fore_cost[dp.prosumer_id] ||= 0
        fore_cost[dp.prosumer_id] += dp.f_consumption * price_cache[dp.f_timestamp.to_i]
        total_costs[:forecast] += dp.f_consumption * price_cache[dp.f_timestamp.to_i]
      end
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate).each do |dp|
        ideal_cost[dp.prosumer_id] ||= 0
        ideal_cost[dp.prosumer_id] += dp.consumption * real_price(dp.timestamp)
        total_costs[:ideal] += dp.consumption * real_price(dp.timestamp)
        real_cost[dp.prosumer_id] ||= 0
        real_cost[dp.prosumer_id] += real_cost(dp, forecast_cache[dp.prosumer_id], price_cache)
        total_costs[:real] += real_cost(dp, forecast_cache[dp.prosumer_id], price_cache)
      end

      @prosumers.map do |p|
        {
            id: p.id,
            name: p.name,
            forecast: fore_cost[p.id],
            ideal: ideal_cost[p.id],
            real: real_cost[p.id]
        }
      end + [total_costs]
    end

    def audit
      for_cache = Hash[DataPoint.where(prosumer: @prosumers,
                                       interval: 2,
                                       f_timestamp: @startDate .. @endDate)
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                       end]
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate).map do |dp|
        {
            timestamp: dp.timestamp,
            prosumer: dp.prosumer.name,
            real: dp.consumption,
            forecast: for_cache[[dp.prosumer_id, dp.timestamp.to_i]],
            price: real_price(dp.timestamp)

        }
      end
    end

    def forecast
      DataPoint
          .joins('INNER JOIN data_points as r ' +
                     'ON r.timestamp = data_points.f_timestamp ' +
                     'AND data_points.prosumer_id = r.prosumer_id ' +
                     'AND data_points.interval_id = r.interval_id')
          .where(prosumer: @prosumers,
                 interval: 2,
                 f_timestamp: @startDate .. @endDate)
          .group('data_points.f_timestamp, data_points.timestamp')
          .order('data_points.f_timestamp')
          .select('data_points.timestamp, data_points.f_timestamp, ' +
                      'sum(data_points.f_consumption) as fc')
          #.sum("data_points.f_consumption")
    end

    def real
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 timestamp: @startDate .. @endDate)
          .group(:timestamp, :f_timestamp)
          .order(:timestamp)
          .select('timestamp, f_timestamp, sum(consumption) as consumption')
#          .sum(:consumption)
    end

    def sum_cost
      for_cache = Hash[DataPoint.where(prosumer: @prosumers,
                                       interval: 2,
                                       f_timestamp: @startDate .. @endDate)
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                       end]
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate).inject({}) do |sum, dp|
        sum[dp.timestamp.to_i] ||= 0
        sum[dp.timestamp.to_i] +=
            real_cost(dp, {
                            dp.timestamp.to_i =>
                                for_cache[[dp.prosumer_id, dp.timestamp.to_i]]
                        }, {dp.timestamp.to_i => real_price(dp.timestamp)})
        sum
      end.map {|k,v| [k*1000,v]}.sort {|a,b| a[0] <=> b[0]}

    end

    def real_cost(f, forecasts, prices)
      forecasts ||= {}
      forecasts[f.timestamp.to_i] ||= 0
      prices[f.timestamp.to_i] ||= 0
      f.consumption > forecasts[f.timestamp.to_i] ?
          forecasts[f.timestamp.to_i] * prices[f.timestamp.to_i] +
              (f.consumption - forecasts[f.timestamp.to_i]) * (1 + @penalty_violation) * real_price(f.timestamp) :
          f.consumption * prices[f.timestamp.to_i] +
              (forecasts[f.timestamp.to_i] - f.consumption) * @penalty_satisfaction * real_price(f.timestamp)

    end

    def real_price(cons_timestamp)
      @real_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 1.year - 1.day) .. (@endDate - 1.year), region_id: 1).map { |d| [(d.date.to_datetime + 1.year + d.dayhour.hours).to_i, d.price * 0.001 ] }] # Convert euro/MWh to euro/KWh
      @real_price_cache[cons_timestamp.to_i] ||= 0
    end

    def forecast_price(cons_timestamp, fore_timestamp)
      @forecast_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 1.year - 1.day) .. (@endDate - 1.year), region_id: 1).map { |d| [(d.date.to_datetime + 1.year + d.dayhour.hours).to_i, d.price * 0.001 ] }] # Convert euro/MWh to euro/KWh
      @forecast_price_cache[cons_timestamp.to_i]
    end

    private

  end

end
