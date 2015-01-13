require 'streamer/sse'  

class StreamController < ApplicationController
  include ActionController::Live

  def addevent

    raise "Missing prosumer" if params[:id].nil?

    raise "Invalid prosumer id" if Prosumer.find_by_id(params[:id]).nil?

    power = rand(-100..100)
    measurement = Measurement.new(timeslot: DateTime.now, power: power, prosumer_id: params[:id] )
    measurement.save

    x = $bunny_channel.fanout("prosumer.#{params[:id]}")

    msg = {'id' => measurement.id, "prosumer_id" => params[:id], 'X' => measurement.timeslot.to_i, 'Y' => power}.to_json

    x.publish(msg)

    render nothing:true
  end
  
  def clusterfeed
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    
    cluster = Cluster.find(params[:id])
    startdate = (params[:startdate].nil?) ? (Time.now - 7.days) : params[:startdate].to_time
    enddate = (params[:enddate].nil?) ? (Time.now) : params[:enddate].to_time 
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]

    idata = cluster.request_cached(interval, startdate, enddate)
    
    idata.each do |d|
      sse.write(d.to_json, event: 'datapoint')  
    end    
    
    x = $bunny_channel.fanout("cluster.#{cluster.id}")
    q = $bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    puts "Subscribing to feed: cluster.#{cluster.id}"  
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      sse.write(data, event: 'datapoint')
      ActiveRecord::Base.connection.close
    end
    
    ActiveRecord::Base.connection.close
    
    loop do
      sleep 1;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.connection.close
    end
          
  rescue IOError
  ensure
    ActiveRecord::Base.connection.close
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end

  def prosumer
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    
    prosumer = Prosumer.find(params[:id])
    startdate = (params[:startdate].nil?) ? (Time.now - 7.days) : params[:startdate].to_time
    enddate = (params[:enddate].nil?) ? (Time.now) : params[:enddate].to_time 
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]
    
    idata = prosumer.request_cached(interval, startdate, enddate)
    
    idata.each do |d|
      sse.write(d.to_json, event: 'datapoint')  
    end
    
 
    x = $bunny_channel.fanout("prosumer.#{params[:id]}")
    q = $bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    puts "Subscribing to: prosumer.#{params[:id]}"
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      # puts "sending: ", data
      sse.write(data, event: 'datapoint')
    end
 
    ActiveRecord::Base.connection.close
    
    loop do
      sleep 1;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.connection.close
    end
  rescue IOError
  ensure
    ActiveRecord::Base.connection.close
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."    
  end

  def meter
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    meter = Meter.find(params[:id])

    x = $bunny_channel.topic("imeter_exchange")
    q = $bunny_channel.queue("", :auto_delete => false).bind(x, :routing_key => "imeter.data.#{meter.mac}")
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      # puts "sending: ", data
      # puts delivery_info, properties, data
      t = DateTime.parse(JSON.parse(data)["t"]).to_i
      p = JSON.parse(data)["kw"]
      sse.write( { timestamp: t,
                   actual: {
                     consumption: p
                    }}.to_json, event: 'datapoint')
    end
    puts "subscribed"

    ActiveRecord::Base.connection.close

    loop do
      sleep 30;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.connection.close
    end
  rescue => e
    puts e.message
    # puts e.backtrace
  ensure
    ActiveRecord::Base.connection.close
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end
end
