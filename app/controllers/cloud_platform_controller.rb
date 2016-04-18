
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
   end

   def resource 
   end

=begin
   def execute

      request_params = params[:cmd].split("&")

      mapper = Hash.new
      mapper["task1"] = 1
      mapper["task2"] = 2
      mapper["task3"] = 3
      mapper["task4"] = 4
      mapper["task5"] = 5
      mapper["task6"] = 6
      mapper["task7"] = 7
      mapper["task8"] = 8
      mapper["task9"] = 9
      mapper["task10"] = 10
      mapper["task11"] = 11
      mapper["task12"] = 12

      sqs = Aws::SQS::Client.new(region: ENGINE_CONFIG[:aws][:region], access_key_id: ENGINE_CONFIG[:aws][:access_key_id], secret_access_key: ENGINE_CONFIG[:aws][:secret_access_key])         

      for index in (1..mapper[request_params[1]])
    
        instance = Instance.new
    
        instance[:user_id] = session["warden.user.user.key"][0][0]
        instance[:configuration_id] = mapper[request_params[1]]
        instance[:status] = 0 
        instance[:instance_name] = request_params[1]+"_"+Time.now.to_i.to_s+"_"+index.to_s
        instance.save

        cmd = Hash.new

        cmd[:action] = "start"
        cmd[:instance_id] = instance[:id]
        cmd[:configuration_id] = instance[:configuration_id]
        cmd[:user_id] = instance[:user_id]

        resp = sqs.send_message(queue_url: ENGINE_CONFIG[:aws][:request_queue_url], message_body:  Base64.encode64(cmd.to_json))

      end
 
    render nothing:true

   end
=end

  def chart
  end

=begin
  def chartData

          instances_simple_2 = Instance.where(worker:"simple", configuration_id: 2, status: "4")
          instances_simple_4 = Instance.where(worker:"simple", configuration_id: 4, status: "4")
          instances_simple_6 = Instance.where(worker:"simple", configuration_id: 6, status: "4")
          instances_simple_8 = Instance.where(worker:"simple", configuration_id: 8, status: "4")
          instances_simple_10 = Instance.where(worker:"simple", configuration_id: 10, status: "4")
          instances_simple_12 = Instance.where(worker:"simple", configuration_id: 12, status: "4")

          instances_cloud_2 = Instance.where(worker:"cloud", configuration_id: 2, status: "4")
          instances_cloud_4 = Instance.where(worker:"cloud", configuration_id: 4, status: "4")
          instances_cloud_6 = Instance.where(worker:"cloud", configuration_id: 6, status: "4")
          instances_cloud_8 = Instance.where(worker:"cloud", configuration_id: 8, status: "4")
          instances_cloud_10 = Instance.where(worker:"cloud", configuration_id: 10, status: "4")
          instances_cloud_12 = Instance.where(worker:"cloud", configuration_id: 12, status: "4")

          cloudData = Array.new
          simpleData = Array.new 
          temp = Array.new
          chartData = Array.new 
         

          instances_simple_2.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          simpleData.push([2, (temp.sum)/(temp.length)])

          temp = []
        
          instances_cloud_2.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end
        
          cloudData.push([2, (temp.sum)/(temp.length)])
          
	  temp = []

          instances_simple_4.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          simpleData.push([4,(temp.sum)/(temp.length)])

          temp = []

          instances_cloud_4.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          cloudData.push([4,(temp.sum)/(temp.length)])

          temp = []

          instances_simple_6.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          simpleData.push([6,(temp.sum)/(temp.length)])

          temp = []

          instances_cloud_6.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          cloudData.push([6,(temp.sum)/(temp.length)])


          temp = []

          instances_simple_8.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
  	  end

          simpleData.push([8,(temp.sum)/(temp.length)])

	  temp = []
	
          instances_cloud_8.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end
	
	  cloudData.push([8,(temp.sum)/(temp.length)])
	  
          temp = []

          instances_simple_10.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          simpleData.push([10, (temp.sum)/(temp.length)])

          temp = []

          instances_cloud_10.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          cloudData.push([10, (temp.sum)/(temp.length)])

          temp = []

          instances_simple_12.each do |instance|
              temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          simpleData.push([12,(temp.sum)/(temp.length)])

          temp = []

          instances_cloud_12.each do |instance|
               temp.push(instance[:updated_at].to_i - instance[:created_at].to_i)
          end

          cloudData.push([12,(temp.sum)/(temp.length)])

          chartData.push({
                       :data => simpleData,
                       :label => "Standalone Server"
                   }, {
                       :data => cloudData,
                       :label => "Cloud Platform"
                   }
                   )

          render :json => chartData
   end

=end

end

