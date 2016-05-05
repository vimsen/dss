require 'rest-client'

class CloudPlatformController < ApplicationController

  before_action :authenticate_user!, :except => [:dataset]

   def index
   end

   def delete
	     ids = params[:id].split("-")
	     Instance.delete(ids)
	     
       ids.each do |id|
          filename = Rails.root.join("storage/"+id.to_s+"_input_dataset.json")
          if File.exist?(filename)
            File.delete(filename)
          end
       end

       render :text => "OK"
   end

   def show
    instance = Instance.find(params[:id])
    @results = instance[:results]
    configuration = ::Configuration.find(instance[:configuration_id])
    @input_params = ActiveSupport::JSON.decode(configuration[:params])
   end

   def instances

      status = Array["Waiting","Submitted","Scheduled","Running","Done","Failed","Cancelled","Unknown","Cancellation"]

      results = Array.new

      instances = Instance.order(created_at: :desc).all

      instances.each do |instance|  
        instance[:status] = status[instance[:status].to_i]
        results.push(instance)
      end

      table_data = { :recordsTotal => results.length, :recordsFiltered => results.length, :data => results  }
  
      render :json => table_data

   end

   def dataset 
      filename = Rails.root.join("storage/"+params[:id].to_s+"_input_dataset.json")
      send_file filename  
   end

   def resources  

     @date = params[:date].to_date unless params[:date].nil?
     @date ||= Date.today

     @period = params[:resources_period] unless params[:resources_period].nil?
     @period ||= "day"
	
     rest_url = 'http://' + ENGINE_CONFIG[:rest_api][:address] + ':'+ ENGINE_CONFIG[:rest_api][:port].to_s + '/api/v1'

     @response_summary =  RestClient.get rest_url + '/summary/' + @period +'/' + @date.to_s
     @response_providers = RestClient.get rest_url + '/providers/' + @period +'/' + @date.to_s
     @response_tasks = RestClient.get rest_url + '/tasks/'+ @period +'/' + @date.to_s 
     @response_analysis = RestClient.get rest_url + '/analysis/'+ @period +'/' + @date.to_s 

  end

   def resource 

     @engine_id = params[:id]
     
     @date = params[:date].to_date unless params[:date].nil?
     @date ||= Date.today
     
     @period = params[:resources_period] unless params[:resources_period].nil?
     @period ||= "day"

     rest_url = 'http://' + ENGINE_CONFIG[:rest_api][:address] + ':'+ ENGINE_CONFIG[:rest_api][:port].to_s + '/api/v1'

     @engine_profile =  RestClient.get rest_url + '/engine/' + @engine_id
     @engine_utilization = RestClient.get rest_url + '/engine_utilization/' + @engine_id + '/' + @period + '/' + @date.to_s
     @engine_cost = RestClient.get rest_url + '/engine_cost/'+ @engine_id +'/' + @period + '/' + @date.to_s

   end

   def machines
   end

   def tasks
   end 

   def chart
   end

end

