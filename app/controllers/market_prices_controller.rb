class MarketPricesController < ApplicationController

  def index

        @mos = MarketOperator.all

        text = { id: -1 , name: "Select Market Operator"}

        @mos.unshift(text)
 
  end

  def regions

      regions = MarketRegion.where(mo_id: params[:id].to_i)
      
      regions.unshift({id: -1, name: "Select Market Operator Zone"})

      render :json=> regions

  end

  def dayAhead

      chartData = Hash.new
      priceData = Array.new
      demandData = Array.new
      volumeSoldData = Array.new
      volumePurchasedData = Array.new

      query_params = params[:id].split('&')
 
      region_id = query_params[0]
 
      #selected_date = Date.today.prev_year + 1
      selected_date = query_params[1].to_date.prev_year + 1

      #actual_day_ahead = Date.today + 1
      actual_day_ahead = query_params[1].to_date + 1

      date_label = actual_day_ahead.to_s

      prices = DayAheadEnergyPrice
                 .order("dayhour")
                 .where(date: selected_date, region_id: region_id)

      volumes = DayAheadEnergyVolume
                 .order("dayhour")
                 .where(date: selected_date, region_id: region_id)

      demands = DayAheadEnergyDemand
                 .order("dayhour")
                 .where(date: selected_date, region_id: region_id)

      prices.each do |price|
        priceData.push([price[:dayhour], price[:price]])
      end

      volumes.each do |volume|
        volumeSoldData.push([volume[:dayhour],volume[:sales]])
        volumePurchasedData.push([volume[:dayhour],volume[:purchases]])
      end

      demands.each do |demand|
        demandData.push([demand[:dayhour],demand[:demand]])
      end

      chartData = { :prices => [{:data => priceData, :label => "Prices - "+date_label}], :volumes => [{:data => volumeSoldData, :label => "Volumes Sold- "+date_label},{:data => volumePurchasedData, :label => "Volumes Purchased - "+date_label}], :demands => [{:data => demandData, :label => "Demands - "+date_label}] }

      render :json => chartData

  end

  def intraDayPrices

      chartData = Array.new
      mi1_priceData = Array.new
      mi2_priceData = Array.new
      mi3_priceData = Array.new
      mi4_priceData = Array.new

      #selected_date = Date.today.prev_year

      query_params = params[:id].split('&')

      region_id = query_params[0]

      selected_date = query_params[1].to_date.prev_year

      mi1_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 1)
      mi2_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 2)
      mi3_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 3)
      mi4_prices = IntraDayEnergyPrice
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
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

      chartData.push( { :data => mi1_priceData, :label => "Energy Price Per Hour - MI1" }, 
                      { :data => mi2_priceData, :label => "Energy Price Per Hour - MI2" }, 
                      { :data => mi3_priceData, :label => "Energy Price Per Hour - MI3" }, 
                      { :data => mi4_priceData, :label => "Energy Price Per Hour - MI4" })

      render :json => chartData

  end

  def intraDayVolumes

      chartData = Array.new

      mi1_salesData = Array.new
      mi1_purchasesData = Array.new
      mi2_salesData = Array.new
      mi2_purchasesData = Array.new
      mi3_salesData = Array.new
      mi3_purchasesData = Array.new
      mi4_salesData = Array.new
      mi4_purchasesData = Array.new

      query_params = params[:id].split('&')

      region_id = query_params[0]

      #selected_date = Date.today.prev_year 
      selected_date = query_params[1].to_date.prev_year

      mi1_volumes = IntraDayEnergyVolume
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 1)
      mi2_volumes = IntraDayEnergyVolume
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 2)
      mi3_volumes = IntraDayEnergyVolume
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 3)
      mi4_volumes = IntraDayEnergyVolume
                     .order("dayhour")
                     .where(date: selected_date,
                            region_id: region_id,
                            interval_id: 4)

      mi1_volumes.each do |volume|
         mi1_salesData.push([volume[:dayhour],volume[:sales]])
         mi1_purchasesData.push([volume[:dayhour],volume[:purchases]])
      end

      mi2_volumes.each do |volume|
         mi2_salesData.push([volume[:dayhour],volume[:sales]])
         mi2_purchasesData.push([volume[:dayhour],volume[:purchases]])
      end

      mi3_volumes.each do |volume|
         mi3_salesData.push([volume[:dayhour],volume[:sales]])
         mi3_purchasesData.push([volume[:dayhour],volume[:purchases]])
      end

      mi4_volumes.each do |volume|
         mi4_salesData.push([volume[:dayhour],volume[:sales]])
         mi4_purchasesData.push([volume[:dayhour],volume[:purchases]])
      end
 
      purchases = Array.new
      sales = Array.new

      purchases.push({:data => mi1_purchasesData, :label => "Purchased Volumes Per Hour - MI1"})
      purchases.push({:data => mi2_purchasesData, :label => "Purchased Volumes Per Hour - MI2"})
      purchases.push({:data => mi3_purchasesData, :label => "Purchased Volumes Per Hour - MI3"})
      purchases.push({:data => mi4_purchasesData, :label => "Purchased Volumes Per Hour - MI4"})
                  
      sales.push({:data => mi1_salesData, :label => "Sold Volumes Per Hour - MI1"})
      sales.push({:data => mi2_salesData, :label => "Sold Volumes Per Hour - MI2"})
      sales.push({:data => mi3_salesData, :label => "Sold Volumes Per Hour - MI3"})
      sales.push({:data => mi4_salesData, :label => "Sold Volumes Per Hour - MI4"})

      render :json => { :sales => sales, :purchases => purchases  }

  end

  def ancillary

      volumes = Array.new
      prices = Array.new

      volumeSold = Array.new
      volumePurchased = Array.new
      minPurchasingPrice = Array.new
      averagePurchasingPrice = Array.new
      maxSellingPrice = Array.new
      averageSellingPrice = Array.new
     
      query_params = params[:id].split('&')

      region_id = query_params[0]

      #selected_date = Date.today.prev_year
      selected_date = query_params[1].to_date.prev_year

      services = AncillaryServicesData.order("dayhour").where(date: selected_date,region_id: region_id)

      services.each do |service|

         volumeSold.push([service[:dayhour],service[:sold_volumes]])
         volumePurchased.push([service[:dayhour],service[:purchased_volumes]])
       
         minPurchasingPrice.push([service[:dayhour],service[:min_purchasing_price]])
         averagePurchasingPrice.push([service[:dayhour],service[:average_purchasing_price]])
         maxSellingPrice.push([service[:dayhour],service[:max_selling_price]])
         averageSellingPrice.push([service[:dayhour],service[:average_selling_price]])

      end

      volumes.push({:data => volumeSold, :label => "Sold Volumes"})
      volumes.push({:data => volumePurchased, :label => "Purchased Volumes"})

      prices.push({:data => minPurchasingPrice, :label => "Minimum Purchasing Price"})
      prices.push({:data => averagePurchasingPrice, :label => "Average Purchasing Price"})
      prices.push({:data => maxSellingPrice, :label => "Maximum Selling Price"})
      prices.push({:data => averageSellingPrice, :label => "Average Selling Price"})

      render :json => { :prices => prices, :volumes => volumes }

  end

  def MBProvisional

      chartData = Array.new

      purchasedRevoked = Array.new
      purchasedNotRevoked = Array.new
      soldRevoked = Array.new
      soldNotRevoked = Array.new

      query_params = params[:id].split('&')

      region_id = query_params[0]

      #selected_date = Date.today.prev_year
      selected_date = query_params[1].to_date.prev_year

      volumes = MbProvisionalTotalData.order("dayhour").where(date: selected_date,region_id: region_id)

      volumes.each do |volume|
         purchasedRevoked.push([volume[:dayhour],volume[:purchased_revoked]])
         purchasedNotRevoked.push([volume[:dayhour],volume[:purchased_not_revoked]])
         soldRevoked.push([volume[:dayhour],volume[:sold_revoked]])
         soldNotRevoked.push([volume[:dayhour],volume[:sold_not_revoked]])
      end

      chartData.push(:data => purchasedRevoked, :label => "Purchased Revoked")
      chartData.push(:data => purchasedNotRevoked, :label => "Purchased Not Revoked")
      chartData.push(:data => soldRevoked, :label => "Sold Revoked")
      chartData.push(:data => soldNotRevoked, :label => "Sold Not Revoked")

      render :json => chartData 
 
  end

  def greenCertificates
      
      selected_date = params[:id].to_date.prev_year

      end_date = selected_date.to_date.end_of_month
      start_date = selected_date.to_date.beginning_of_month
  
      certificates = GreenCertificate.where("date >= ? AND date <= ? AND price_reference > 0", start_date, end_date)

      for index in (0..certificates.length-1)
         certificates[index][:date] = certificates[index][:date].to_date
         certificates[index][:price_reference] = certificates[index][:price_reference].round(2)
         certificates[index][:price_maximum] = certificates[index][:price_maximum].round(2)
         certificates[index][:price_minimum] = certificates[index][:price_minimum].round(2)
      end


      table_data = { :recordsTotal => certificates.length, :recordsFiltered => certificates.length, :data => certificates }

      render :json => table_data
  
  end


  def efficiencyCertificates
  
      selected_date = params[:id].to_date.prev_year

      end_date = selected_date.to_date.end_of_month
      start_date = selected_date.to_date.beginning_of_month

      certificates = EnergyEfficiencyCertificate.where("date >= ? AND date <= ? AND price_reference > 0", start_date, end_date)

      for index in (0..certificates.length-1)
         certificates[index][:date] = certificates[index][:date].to_date
         certificates[index][:price_reference] = certificates[index][:price_reference].round(2)
         certificates[index][:price_maximum] = certificates[index][:price_maximum].round(2)
         certificates[index][:price_minimum] = certificates[index][:price_minimum].round(2)
      end


      table_data = { :recordsTotal => certificates.length, :recordsFiltered => certificates.length, :data => certificates }

      render :json => table_data
  
  end

end
