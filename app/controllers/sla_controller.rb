class SlaController < ApplicationController
  def monitor
    @date = params[:date].to_date unless params[:date].nil?
    @date ||= Date.today

    @accepted_bids = Bid.accepted.where(date: @date)

    @chart_data = [{
        label: "SLA",
        data: SlaItem.where(bid: @accepted_bids).order(timestamp: :asc).group(:timestamp).sum(:volume).map {|k,v| [k.to_i * 1000, v]}
    },{
        label: "Real Prosumption",
        data: DataPoint.select("timestamp, SUM(COALESCE(consumption,0) - COALESCE(production,0)) AS pros")
                  .where(interval: 2, timestamp: @date.beginning_of_day .. @date.end_of_day)
                  .group(:timestamp)
                  .order(timestamp: :asc)
                  .map{|dp| [dp.timestamp.to_i * 1000, dp.pros]}
    },{
        label: "Forecast Prosumpton",
        data: DataPoint.select("f_timestamp, SUM(COALESCE(f_consumption,0) - COALESCE(f_production,0)) AS f_pros")
                  .where(interval: 2, f_timestamp: @date.beginning_of_day .. @date.end_of_day)
                  .group(:f_timestamp)
                  .order(f_timestamp: :asc)
                  .map{|dp| [dp.f_timestamp.to_i * 1000, dp.f_pros]}
    }]

  end
end
