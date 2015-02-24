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
      [
          {
              label: "forecast",
              data: forecast.map do |f|
                forecast_cache[f.f_timestamp.to_i] = f.fc
                price_cache[f.f_timestamp.to_i] = f.fc * forecast_price(f.f_timestamp, f.timestamp)
                [f.f_timestamp.to_i * 1000, price_cache[f.f_timestamp.to_i]]
              end
          },{
              label: "ideal",
              data: real.map do |f|
                [f.timestamp.to_i * 1000, f.c * real_price(f.timestamp)]
              end
          },{
              label: "real",
              data: real.map do |f|
                [f.timestamp.to_i * 1000, real_cost(f, forecast_cache, price_cache)]
              end
          }
      ]
    end

    def forecast
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 f_timestamp: @startDate.. @endDate)
          .group(:f_timestamp, :timestamp)
          .order(:f_timestamp)
          .select('timestamp, f_timestamp, sum(f_consumption) as fc')
#          .sum(:f_consumption)
    end

    def real
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 timestamp: @startDate.. @endDate)
          .group(:timestamp, :f_timestamp)
          .order(:timestamp)
          .select('timestamp, f_timestamp, sum(consumption) as c')
#          .sum(:consumption)
    end

    private

    def real_cost(f, forecasts, prices)
      return nil if forecasts[f.timestamp.to_i].nil?
      f.c > forecasts[f.timestamp.to_i] ?
          forecasts[f.timestamp.to_i] * prices[f.timestamp.to_i] +
              (f.c - forecasts[f.timestamp.to_i]) * (1 + @penalty_violation) * real_price(f.timestamp) :
          f.c * prices[f.timestamp.to_i] +
              (forecasts[f.timestamp.to_i] - f.c) * @penalty_satisfaction * real_price(f.f_timestamp)

    end

    def real_price(cons_timestamp)
      f_date = cons_timestamp.in_time_zone("UTC").to_date - 1.year
      f_dayhour = cons_timestamp.in_time_zone("UTC").hour + 1
      DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).first.price
    end

    def forecast_price(cons_timestamp, fore_timestamp)
      f_date = cons_timestamp.in_time_zone("UTC").to_date - 1.year
      f_dayhour = cons_timestamp.in_time_zone("UTC").hour + 1

      DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).count > 0 ?
          DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).first.price :
          nil
    end

  end

end