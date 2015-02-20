module Market

  class Calculator

    def initialize(prosumers: nil, startDate: nil, endDate: nil)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end

    def forecastCost
      forecast.map do |f|
        f.fc * forecast_price(f.f_timestamp,f.timestamp)

      end
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
      f_dayhour = cons_timestamp.in_time_zone("UTC").hour

      DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).count > 0 ?
          DayAheadEnergyPrice.where(date: f_date, dayhour: f_dayhour).first.price :
          nil
    end

    private

    def convert(timestamp)

    end

  end

end