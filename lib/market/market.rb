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
 

    def calcCosts2
      DataPoint.joins("LEFT JOIN forecasts ON forecasts.timestamp = data_points.timestamp AND data_points.prosumer_id = forecasts.prosumer_id AND data_points.interval_id = forecasts.interval_id")
               .joins("INNER JOIN day_ahead_energy_prices as da ON data_points.timestamp::date = da.date AND to_char(data_points.timestamp, ' HH24') = to_char(da.dayhour, '00')")
               .group(:timestamp)
               .select(:timestamp, 'sum(price * (coalesce(data_points.consumption,0) - coalesce(data_points.production,0))) as ideal_cost', 'sum(price * (coalesce(forecasts.consumption,0) - coalesce(forecasts.production,0))) as forecast_cost')
               .order('forecast_cost ASC')
               .map{|t| [t.timestamp, t.ideal_cost, t.forecast_cost]}
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
                      forecast_cache[f.f_timestamp.to_i] = f.forecast_prosumption
                      price_cache[f.f_timestamp.to_i] = forecast_price(f.f_timestamp, f.timestamp)
                     #  Rails.logger.debug "timestamp: #{f.f_timestamp}, price: #{forecast_price(f.f_timestamp, f.timestamp)}"
                      Rails.logger.debug "fc: #{f.forecast_prosumption}, pc: #{price_cache}, ts: #{f.f_timestamp.to_i}, cache: #{price_cache}" unless price_cache[f.f_timestamp.to_i]
                      aggr_costs[:forecast] += f.forecast_prosumption * price_cache[f.f_timestamp.to_i]
                      [f.f_timestamp.to_i * 1000, f.forecast_prosumption * price_cache[f.f_timestamp.to_i]]
                    end
                }, {
                    label: "ideal",
                    data: real.map do |f|
                      # Rails.logger.debug "prosumption: #{f.prosumption}"
                      aggr_costs[:ideal] += f.prosumption * real_price(f.timestamp) unless f.prosumption.nil?
                      [f.timestamp.to_i * 1000, f.prosumption * real_price(f.timestamp)] unless f.prosumption.nil?
                    end
                },  {
                    label: "individual",
                    data: sum_cost
                },{
                    label: "cluster",
                    data: real.map do |f|
                      aggr_costs[:real] += real_cost(f, forecast_cache, {f.timestamp.to_i => real_price(f.timestamp)})
                      [f.timestamp.to_i * 1000, real_cost(f, forecast_cache, {f.timestamp.to_i => real_price(f.timestamp)})]
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
                      f_timestamp: @startDate .. @endDate)
          .select("timestamp, f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption").each do |dp|
        forecast_cache[dp.prosumer_id] ||= {}
        forecast_cache[dp.prosumer_id][dp.f_timestamp.to_i] = dp.f_prosumption
        price_cache ||= {}
        price_cache[dp.f_timestamp.to_i] = forecast_price(dp.f_timestamp, dp.timestamp)
        fore_cost[dp.prosumer_id] ||= 0
        # puts "#{dp.f_prosumption}, #{price_cache[dp.f_timestamp.to_i]}"
        fore_cost[dp.prosumer_id] += dp.f_prosumption * price_cache[dp.f_timestamp.to_i]
        total_costs[:forecast] += dp.f_prosumption * price_cache[dp.f_timestamp.to_i]
      end
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate)
          .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption").each do |dp|
        ideal_cost[dp.prosumer_id] ||= 0
        ideal_cost[dp.prosumer_id] += dp.prosumption * real_price(dp.timestamp) unless dp.prosumption.nil?
        total_costs[:ideal] += dp.prosumption * real_price(dp.timestamp) unless dp.prosumption.nil?
        real_cost[dp.prosumer_id] ||= 0
        real_cost[dp.prosumer_id] += real_cost(dp, forecast_cache[dp.prosumer_id], {dp.timestamp.to_i => real_price(dp.timestamp)})
        total_costs[:real] += real_cost(dp, forecast_cache[dp.prosumer_id], {dp.timestamp.to_i => real_price(dp.timestamp)})
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
                           .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
                           .map do |dp|
        [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_prosumption]
      end]
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate)
          .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
          .map do |dp|
        {
            timestamp: dp.timestamp,
            prosumer: Prosumer.find(prosumer_id).name,
            real: dp.prosumption,
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
                      'sum(COALESCE(data_points.f_consumption,0)) - sum(COALESCE(data_points.f_production,0)) as forecast_prosumption')
          #.sum("data_points.f_consumption")
    end

    def real
      DataPoint
          .where(prosumer: @prosumers,
                 interval: 2,
                 timestamp: @startDate .. @endDate)
          .group(:timestamp, :f_timestamp)
          .order(:timestamp)
          .select('timestamp, f_timestamp, sum(COALESCE(consumption,0)) - sum(COALESCE(production,0)) as prosumption')
#          .sum(:consumption)
    end

    def sum_cost
      for_cache = Hash[DataPoint.where(prosumer: @prosumers,
                                       interval: 2,
                                       f_timestamp: @startDate .. @endDate)
                           .select("f_timestamp, prosumer_id, COALESCE(f_consumption,0) - COALESCE(f_production,0) as f_prosumption")
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_prosumption]
                       end]
      DataPoint.where(prosumer: @prosumers,
                      interval: 2,
                      timestamp: @startDate .. @endDate)
          .select("timestamp, prosumer_id, COALESCE(consumption,0) - COALESCE(production,0) as prosumption")
          .inject({}) do |sum, dp|
        sum[dp.timestamp.to_i] ||= 0
        sum[dp.timestamp.to_i] +=
            (real_cost(dp, {
                            dp.timestamp.to_i =>
                                for_cache[[dp.prosumer_id, dp.timestamp.to_i]]
                        }, {dp.timestamp.to_i => real_price(dp.timestamp)})) || 0
        sum
      end.map {|k,v| [k*1000,v]}.sort {|a,b| a[0] <=> b[0]}

    end

    def real_cost(f, forecasts, prices)
      forecasts ||= {}
      forecasts[f.timestamp.to_i] ||= 0
      prices[f.timestamp.to_i] ||= 0
     #  puts "testing: #{f.prosumption}, #{prices[f.timestamp.to_i]}, #{forecasts[f.timestamp.to_i]}, #{f.prosumption * prices[f.timestamp.to_i] +
     #      (forecasts[f.timestamp.to_i] - f.prosumption) * @penalty_satisfaction * real_price(f.timestamp)}"
      return 0 if f.prosumption.nil?
      f.prosumption > forecasts[f.timestamp.to_i] ?
            forecasts[f.timestamp.to_i] * prices[f.timestamp.to_i] +
                (f.prosumption - forecasts[f.timestamp.to_i]) * (1 + @penalty_violation) * real_price(f.timestamp) :
            f.prosumption * prices[f.timestamp.to_i] +
                (forecasts[f.timestamp.to_i] - f.prosumption) * @penalty_satisfaction * real_price(f.timestamp)
    end

    def penalty_for_single(day_ahead_amount)
      # day_ahead_cost = day_ahead_amount * real_price(@startDate)

      f = real()

      raise "Multiple Results" if f.length > 1

      f = [ Struct.new(:timestamp, :prosumption).new(@startDate, 0) ] if f.length == 0

      actual_amount = f.first.prosumption

      #final_cost = real_cost(f.first,
      #                       {@startDate.to_i => day_ahead_amount},
      #                       {@startDate.to_i => real_price(@startDate)})

      #final_cost - day_ahead_cost

      imbalance = day_ahead_amount - actual_amount

      (imbalance > 0 ? @penalty_satisfaction : - @penalty_violation) * imbalance * real_price(@startDate)

    end

    def real_price(cons_timestamp)
      @real_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 365.days - 1.day - 2.hours) .. (@endDate - 365.days), region_id: 1).map { |d| [(d.date.to_datetime + 365.days + d.dayhour.hours).to_i, d.price * 0.001 ] }] # Convert euro/MWh to euro/KWh
      # Rails.logger.debug "ts: #{cons_timestamp}, Cache: #{@real_price_cache}"
      @real_price_cache[cons_timestamp.to_i] ||= 0
    end

    def forecast_price(cons_timestamp, fore_timestamp)
      @forecast_price_cache ||= Hash[DayAheadEnergyPrice.where(date: (@startDate - 365.days - 1.day - 2.hours) .. (@endDate - 365.days), region_id: 1).map { |d| [(d.date.to_datetime + 365.days + d.dayhour.hours).to_i, d.price * 0.001 ] }] # Convert euro/MWh to euro/KWh      puts "timestamp: #{cons_timestamp}, price: #{@forecast_price_cache[cons_timestamp.to_i]}, total: #{@forecast_price_cache}"
    #   Rails.logger.debug "ts: #{cons_timestamp}, For. Cache: #{@forecast_price_cache}, startDate: #{@startDate}, endDate: #{@endDate}"
      @forecast_price_cache[cons_timestamp.to_i]
    end

    private

  end

end
