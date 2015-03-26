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

   def instances

	status = Array["","Submitted","Scheduled","Running","Done","Failed"]

	results = Array.new

	instances = Instance.order(created_at: :desc).all

	instances.each do |instance|	
		instance[:status] = status[instance[:status].to_i]
		results.push(instance)
	end

	render :json => results

   end
   
   def responses

	begin

           response.headers['Content-Type'] = 'text/event-stream'
           sse = Streamer::SSE.new(response.stream)
	   sse.write('Instance', event: 'refresh')
=begin
   	   last_updated = Instance.find_by_id(1)

   	   #if last_updated.created_at.to_i > 5.seconds.ago.to_i or last_updated.updated_at.to_i < 3.seconds.ago.to_i
	   if last_updated.updated_at.to_i > last_updated[:market_id] or last_updated.updated_at.to_i < last_updated[:market_id]-2
               sse.write('Task', event: 'refresh')
	       puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	       last_updated[:market_id]	 = Time.now.to_i
	       last_updated.save
	   end
=end
	   render :text => "OK"
	
        rescue IOError
        ensure
              ActiveRecord::Base.connection.close
              sse.close
        end

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
