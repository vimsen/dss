class SlaController < ApplicationController

  def monitor
    @date = params[:date].to_date unless params[:date].nil?
    @date ||= Date.today

    @category = params[:category].first.to_i unless params[:category].nil?
    @category ||= ProsumerCategory.first.id

    @forecasts = params[:forecasts] unless params[:forecasts].nil?
    @forecasts ||= "FMS-D"


    @accepted_bids = Bid.accepted.where(date: @date)

    @chart_data = [{
        label: "SLA",
        data: SlaItem.where(bid: @accepted_bids).order(timestamp: :asc).group(:timestamp).sum(:volume).map {|k,v| [k.to_i * 1000, v]}
    },{
        label: "Real Prosumption",
        data: DataPoint.select("timestamp, SUM(COALESCE(consumption,0) - COALESCE(production,0)) AS pros")
                  .where(interval: 2, timestamp: @date.beginning_of_day .. @date.end_of_day, prosumer: Prosumer.category(@category)) # prosumer_id: [20001..20033, 20089..20124] )   #
                  .where('production IS NOT NULL OR consumption IS NOT NULL')
                  .group(:timestamp)
                  .order(timestamp: :asc)
                  .map{|dp| [dp.timestamp.to_i * 1000, dp.pros]}
    }] + getForecastObj + [{
        label: "",
        data: [[@date.noon.to_datetime.to_i * 1000, 0]],
        points: {
            show: false
        }

=begin
        data: DataPoint.select("f_timestamp, SUM(COALESCE(f_consumption,0) - COALESCE(f_production,0)) AS f_pros")
                  .where(interval: 2, f_timestamp: @date.beginning_of_day .. @date.end_of_day)
                  .group(:f_timestamp)
                  .order(f_timestamp: :asc)
                  .map{|dp| [dp.f_timestamp.to_i * 1000, dp.f_pros]}
=end
    }]
  end

  private
  def getForecastObj
    case @forecasts
      when "none"
        []
      when "edms"
        [{
             label: "Forecast Prosumpton",
             data: DataPoint.select("f_timestamp, SUM(COALESCE(f_consumption,0) - COALESCE(f_production,0)) AS f_pros")
                       .where(interval: 2, f_timestamp: @date.beginning_of_day .. @date.end_of_day, prosumer: Prosumer.category(@category)) # prosumer_id: [20001..20033, 20089..20124] )   #
                       .where('f_production IS NOT NULL OR f_consumption IS NOT NULL')
                       .group(:f_timestamp)
                       .order(f_timestamp: :asc)
                       .map{|dp| [dp.f_timestamp.to_i * 1000, dp.f_pros]}
         }]
      when "FMS-D"
        [{
            label: "Forecast Prosumpton",
            data: Forecast.day_ahead
                      .select("timestamp, SUM(COALESCE(consumption,0) - COALESCE(production,0)) AS f_pros")
                      .where(interval: 2, timestamp: @date.beginning_of_day .. @date.end_of_day, prosumer: Prosumer.category(@category)) # prosumer_id: [20001..20033, 20089..20124] )   # : Prosumer.category(4))
                      .where('production IS NOT NULL OR consumption IS NOT NULL')
                      .group(:timestamp)
                      .order(timestamp: :asc)
                      .map{|dp| [dp.timestamp.to_i * 1000, dp.f_pros]}
        }]
      else
        []
    end
  end
end
