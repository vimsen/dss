class MarketPricesController < ApplicationController

  def index
  end

  def dayAhead

    chartData = Array.new
    priceData = Array.new

    selected_date = Date.today.prev_year + 1

    actual_day_ahead = Date.today + 1

    date_label = actual_day_ahead.to_s

    prices = DayAheadEnergyPrice
                 .order("dayhour")
                 .where(date: selected_date, market_id: params[:id])

    prices.each do |price|
      hour_price = Array.new
      hour_price.push(price[:dayhour])
      hour_price.push(price[:price])
      priceData.push(hour_price)
    end

    chartData.push({:data => priceData, :label => "Energy Price - "+date_label})

    render :json => chartData

  end

  def intraDay

    chartData = Array.new
    mi1_priceData = Array.new
    mi2_priceData = Array.new
    mi3_priceData = Array.new
    mi4_priceData = Array.new

    selected_date = Date.today.prev_year

    mi1_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            market_id: params[:id],
                            interval_id: 1)
    mi2_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            market_id: params[:id],
                            interval_id: 2)
    mi3_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            market_id: params[:id],
                            interval_id: 3)
    mi4_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            market_id: params[:id],
                            interval_id: 4)

    mi1_prices.each do |price|
      hour_price = Array.new
      hour_price.push(price[:dayhour])
      hour_price.push(price[:price])
      mi1_priceData.push(hour_price)
    end

    mi2_prices.each do |price|
      hour_price = Array.new
      hour_price.push(price[:dayhour])
      hour_price.push(price[:price])
      mi2_priceData.push(hour_price)
    end

    mi3_prices.each do |price|
      hour_price = Array.new
      hour_price.push(price[:dayhour])
      hour_price.push(price[:price])
      mi3_priceData.push(hour_price)
    end

    mi4_prices.each do |price|
      hour_price = Array.new
      hour_price.push(price[:dayhour])
      hour_price.push(price[:price])
      mi4_priceData.push(hour_price)
    end

    chartData.push({
                       :data => mi1_priceData,
                       :label => "Energy Price Per Hour - MI1"
                   }, {
                       :data => mi2_priceData,
                       :label => "Energy Price Per Hour - MI2"
                   }, {
                       :data => mi3_priceData,
                       :label => "Energy Price Per Hour - MI3"
                   }, {
                       :data => mi4_priceData,
                       :label => "Energy Price Per Hour - MI4"
                   })

    render :json => chartData
  end
end
