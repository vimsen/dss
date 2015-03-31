require 'streamer/sse'

class CloudPlatformController < ApplicationController
   include ActionController::Live

   def index
   end

   def delete
	ids = params[:id].split("-")
	Instance.delete(ids)
	render :text => "OK"
   end

  def chart
  end

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

   def instances

	status = Array["","Submitted","Scheduled","Running","Done","Failed"]

	results = Array.new

	instances = Instance.order(created_at: :desc).all

	instances.each do |instance|	
		instance[:status] = status[instance[:status].to_i]
		results.push(instance)
	end


	table_data = { :recordsTotal => results.length, :recordsFiltered => results.length, :data => results  }
	
	render :json => table_data

   end

   def execute

        exchange_name = "vimsen_platform"
        requests_queue = "vimsen_platform_requests"
	routing_key = "vimsen_platform_requests"

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

	request_params = params[:cmd].split("&")

        bunny_channel = $bunny.create_channel
 	x = bunny_channel.direct(exchange_name, :durable => true)
        q = bunny_channel.queue(requests_queue, :durable => true)
	q.bind(x, :routing_key => routing_key )
	for index in (1..mapper[request_params[1]])

		instance = Instance.new
		instance.user_id = session["warden.user.user.key"][0][0]
		instance.configuration_id = mapper[request_params[1]]
		instance.worker = request_params[0]
		instance.status	= 1	
		instance.instance_name = request_params[1]+"_"+Time.now.to_i.to_s+"_"+index.to_s
		instance.save

		log_instance = LogInstance.new
		log_instance.status = 1
		log_instance.instance_id = instance.id
		log_instance.save

		cmd = { :engine => request_params[0] , :task => "task", :instance => instance.id, :index => index }

		x.publish(cmd.to_json , :routing_key => routing_key)
	end

	render nothing:true
   end

end
