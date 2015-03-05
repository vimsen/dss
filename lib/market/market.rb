module Market

  class Calculator

    def initialize(prosumers: nil, startDate: nil, endDate: nil,
                   penalty_violation: 0.3, penalty_satisfaction: 0.2)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end

    def calcCosts
      forecast_cache = {}
      price_cache = {}
      aggr_costs = {id: -2, name: :aggregated, forecast: 0, ideal: 0, real: 0}
      {
          plot: [
              {
                  label: "forecast",
                  data: forecast.map do |f|
                    forecast_cache[f.f_timestamp.to_i] = f.fc
                    price_cache[f.f_timestamp.to_i] = forecast_price(f.f_timestamp, f.timestamp)
                    unless price_cache[f.f_timestamp.to_i].nil?
                      aggr_costs[:forecast] += f.fc * price_cache[f.f_timestamp.to_i]
                      [f.f_timestamp.to_i * 1000, f.fc * price_cache[f.f_timestamp.to_i]]
                    else
                      nil
                    end
                  end
              }, {
                  label: "ideal",
                  data: real.map do |f|
                    unless price_cache[f.timestamp.to_i].nil?
                      aggr_costs[:ideal] += f.consumption * real_price(f.timestamp)
                      [f.timestamp.to_i * 1000, f.consumption * real_price(f.timestamp)]
                    else
                      nil
                    end
                  end
              }, {
                  label: "real",
                  data: real.map do |f|
                    unless price_cache[f.timestamp.to_i].nil?
                      aggr_costs[:real] += real_cost(f, forecast_cache, price_cache)
                      [f.timestamp.to_i * 1000, real_cost(f, forecast_cache, price_cache)]
                    else
                      nil
                    end
                  end
              }
          ],
          dissagrgated: calcDiss + [aggr_costs],

      }
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
        price_cache[dp.prosumer_id] ||= {}
        price_cache[dp.prosumer_id][dp.f_timestamp.to_i] = forecast_price(dp.f_timestamp, dp.timestamp)
        fore_cost[dp.prosumer_id] ||= 0
        fore_cost[dp.prosumer_id] += dp.f_consumption * price_cache[dp.prosumer_id][dp.f_timestamp.to_i]
        total_costs[:forecast] += dp.f_consumption * price_cache[dp.prosumer_id][dp.f_timestamp.to_i]
      end
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate).each do |dp|
        ideal_cost[dp.prosumer_id] ||= 0
        ideal_cost[dp.prosumer_id] += dp.consumption * real_price(dp.timestamp)
        total_costs[:ideal] += dp.consumption * real_price(dp.timestamp)
        real_cost[dp.prosumer_id] ||= 0
        real_cost[dp.prosumer_id] += real_cost(dp, forecast_cache[dp.prosumer_id], price_cache[dp.prosumer_id]) unless  price_cache[dp.prosumer_id][dp.timestamp.to_i].nil?
        total_costs[:real] += real_cost(dp, forecast_cache[dp.prosumer_id], price_cache[dp.prosumer_id]) unless  price_cache[dp.prosumer_id][dp.timestamp.to_i].nil?
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


    def forecast
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 f_timestamp: @startDate .. @endDate)
          .group(:f_timestamp, :timestamp)
          .order(:f_timestamp)
          .select('timestamp, f_timestamp, sum(f_consumption) as fc')
#          .sum(:f_consumption)
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


    def real_cost(f, forecasts, prices)
      return nil if forecasts[f.timestamp.to_i].nil?
      #puts "@@@@@", f.c, prices[f.timestamp.to_i], (forecasts[f.timestamp.to_i] - f.c), @penalty_satisfaction, real_price(f.timestamp)
      f.consumption > forecasts[f.timestamp.to_i] ?
          forecasts[f.timestamp.to_i] * prices[f.timestamp.to_i] +
              (f.consumption - forecasts[f.timestamp.to_i]) * (1 + @penalty_violation) * real_price(f.timestamp) :
          f.consumption * prices[f.timestamp.to_i] +
              (forecasts[f.timestamp.to_i] - f.consumption) * @penalty_satisfaction * real_price(f.timestamp)

    end

    def real_price(cons_timestamp)
      @real_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 1.year - 1.day) .. (@endDate - 1.year)).map { |d| [(d.date.to_datetime + 1.year + d.dayhour.hours).to_i, d.price] }]
      # puts "@@@@@@@@@@@@@@", cons_timestamp, @real_price_cache[cons_timestamp], @real_price_cache
      @real_price_cache[cons_timestamp.to_i]
    end

    def forecast_price(cons_timestamp, fore_timestamp)

      @forecast_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 1.year - 1.day) .. (@endDate - 1.year)).map { |d| [(d.date.to_datetime + 1.year + d.dayhour.hours).to_i, d.price] }]
      # puts "@@@@@@@@@@@@@@", cons_timestamp.to_i, @forecast_price_cache[cons_timestamp.to_i], @forecast_price_cache
      @forecast_price_cache[cons_timestamp.to_i]
    end

    private

  end

end