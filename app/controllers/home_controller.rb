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

         currentTime = Time.new

         #@prices = EnergyPrice.order("dayhour").where(date:currentTime.strftime("%Y-%m-%d"))
         @prices = EnergyPrice.order("dayhour").where(date:"2014-10-01",country:"GREC")
         @prices.each do |price|
             hour_price = Array.new
             hour_price.push(price[:dayhour])
             hour_price.push(price[:price])     
             priceData.push(hour_price)
         end

         chartData.push({"data"=>priceData,"label"=>"Energy Price"})
         
         render :json => chartData
        
    end
  
    def totalProsumption
    end
  
    def top5Producers
          top5producers = Array.new  
          
          render :json => top5Producers
    end
end