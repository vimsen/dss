class HomeController < ApplicationController

    def index  
    end

    def energyType
       
        chartData = Array.new  
        
        
        @availableEnergyTypes = EnergyType.select("id","name") 
           
        @availableEnergyTypes.each do |type|
            type_data = Hash.new    
            type_data[:label] = type[:name]
            type_data[:data] = EnergyTypeProsumer.where(energy_type_id: type[:id]).count
            chartData.push(type_data)
        end
        
        render :json => chartData
          
    end

    def energyPrice
         
         chartData = Array.new  
         priceData = Array.new  

         selected_date = Date.today-30

         @prices = DayAheadEnergyPrice.order("dayhour").where(date:selected_date,market_id:1)

         @prices.each do |price|
             hour_price = Array.new
             hour_price.push(price[:dayhour])
             hour_price.push(price[:price])     
             priceData.push(hour_price)
         end

         chartData.push({"data"=>priceData,"label"=>"Energy Price Per DayHour"})
         
         render :json => chartData
        
    end
  
  
  
    def totalProsumption
      chartData = Array.new  
     # Time.zone = 'Athens'
   #   print("Tiiiiime::")
   #   print(Time.zone.now-1.day)
        @totalConsumption=DataPoint.order(timestamp: :asc).where(interval:2).where("timestamp >= ?",Time.zone.now.beginning_of_day - 1.day).group(:timestamp).select("timestamp, sum(consumption)").map {|dp| {time: dp["timestamp"], sum: dp["sum"]} }
         totalconsumption = []
         
        @totalProduction=DataPoint.order(timestamp: :asc).where(interval:2).where("timestamp >= ?",Time.zone.now.beginning_of_day - 1.day).group(:timestamp).select("timestamp, sum(production)").map {|dp| {time: dp["timestamp"], sum: dp["sum"]} }
         totalproduction =[]
      
        @totalConsumption.each do |consumption|
         consumption_data= Hash.new  
         consumption_data[:label]= "Total Consumption"
         consumption_data[:data]= consumption[:sum]
        totalconsumption.push(consumption_data)
        end
        
        @totalProduction.each do |production|
         production_data= Hash.new  
         production_data[:label]= "Total Production"
         production_data[:data]= production[:sum]
         totalproduction.push(production_data)
        end
        
      chartData.push({"data"=>totalconsumption,"label"=>"Total Consumption"},{"data"=>totalproduction,"label"=>"Total Production"})
      
      render :json => chartData
    end
  
  
    def top5Producers   
      chartData = Array.new 
      top5producersNames=Array.new
     
  #  @top5prosumers=DataPoint.joins(:prosumer).order(consumption: :desc).where(timestamp: currentTime.strftime("%Y-%m-%d")).limit(5)
        @top5prosumers=DataPoint.joins(:prosumer).order(production: :desc).where(interval: 3).where("timestamp >= ?",Time.zone.now - 1.day).limit(5)
        data = []
        names= []
        i=0
        @top5prosumers.each do |production|
           #data.push([production.prosumer.name, production.consumption])
           i=i+1
           data.push([i, production.production])
           names.push([i,production.prosumer.name])
        end
      
          chartData.push({"data"=>data,"label"=>"Total Energy Production"},{"names"=>names,"label"=>"Producers Names"})
          
          render :json => chartData 
    end
    
    def top5Consumers     
      chartData = Array.new 
      top5consumersNames=Array.new
     
        @top5consumers=DataPoint.joins(:prosumer).order(consumption: :desc).where(interval: 3).where("timestamp >= ?",Time.zone.now - 1.day).limit(5)
        data = []
        names= []
        i=0
        @top5consumers.each do |consumption|
           #data.push([production.prosumer.name, production.consumption])
           i=i+1
           data.push([i, consumption.consumption])
           names.push([i,consumption.prosumer.name])
        end
      
          chartData.push({"data"=>data,"label"=>"Total Energy Consumption"},{"names"=>names,"label"=>"Consumers Names"})
          
          render :json => chartData 
     end
end
