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
      {
          plot: [
              {
                  label: "forecast",
                  data: forecast.map do |f|
                    forecast_cache[f.f_timestamp.to_i] = f.fc
                    price_cache[f.f_timestamp.to_i] = forecast_price(f.f_timestamp, f.timestamp)
                    unless price_cache[f.f_timestamp.to_i].nil?
                      [f.f_timestamp.to_i * 1000, f.fc * price_cache[f.f_timestamp.to_i]]
                    else
                      nil
                    end
                  end
              }, {
                  label: "ideal",
                  data: real.map do |f|
                    unless price_cache[f.timestamp.to_i].nil?
                      [f.timestamp.to_i * 1000, f.c * real_price(f.timestamp)]
                    else
                      nil
                    end
                  end
              }, {
                  label: "real",
                  data: real.map do |f|
                    unless price_cache[f.timestamp.to_i].nil?
                      [f.timestamp.to_i * 1000, real_cost(f, forecast_cache, price_cache)]
                    else
                      nil
                    end
                  end
              }
          ]
      }
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
          .select('timestamp, f_timestamp, sum(consumption) as c')
#          .sum(:consumption)
    end


    def real_cost(f, forecasts, prices)
      return nil if forecasts[f.timestamp.to_i].nil?
      #puts "@@@@@", f.c, prices[f.timestamp.to_i], (forecasts[f.timestamp.to_i] - f.c), @penalty_satisfaction, real_price(f.timestamp)
      f.c > forecasts[f.timestamp.to_i] ?
          forecasts[f.timestamp.to_i] * prices[f.timestamp.to_i] +
              (f.c - forecasts[f.timestamp.to_i]) * (1 + @penalty_violation) * real_price(f.timestamp) :
          f.c * prices[f.timestamp.to_i] +
              (forecasts[f.timestamp.to_i] - f.c) * @penalty_satisfaction * real_price(f.timestamp)

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