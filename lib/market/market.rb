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
      forecast.map do |f|
        {
            timestamp: f.f_timestamp,
            forecast_cost: f.fc * forecast_price(f.f_timestamp, f.timestamp),
            ideal_cost: f.c * real_price(f.f_timestamp),
            real_cost: real_cost(f)
        }
      end
    end

    private

    def real_cost(f)
      f.c > f.fc ?
          f.fc * forecast_price(f.f_timestamp, f.timestamp) +
              (f.c - f.fc) * (1 + @penalty_violation) * real_price(f.f_timestamp) :
          f.c * forecast_price(f.f_timestamp, f.timestamp) +
              (f.fc - f.c) * @penalty_satisfaction * real_price(f.f_timestamp)

    end

    def real_price(cons_timestamp)
      f_date = cons_timestamp.in_time_zone("UTC").to_date - 1.year
      f_dayhour = cons_timestamp.in_time_zone("UTC").hour + 1
      DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).first.price
    end

    def forecast
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 f_timestamp: @startDate.. @endDate)
          .group(:timestamp,:f_timestamp)
          .order(:f_timestamp)
          .select('timestamp, f_timestamp, sum(consumption) as c, sum(f_consumption) as fc')
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