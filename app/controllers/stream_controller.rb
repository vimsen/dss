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

    startdate = (params[:startdate].nil?) ? (Time.now - 2.days) : params[:startdate].to_time
    enddate = (params[:enddate].nil?) ? (Time.now + 1.days) : params[:enddate].to_time
   # puts date
    consumers = []
    cluster.prosumers.each do |p|
      p.measurements.where(timeslot: startdate..enddate).order(timeslot: :asc).last(200).each do |m|
        sse.write({:id => m.id, :prosumer_id => p.id, :X => m.timeslot.to_i, :Y => m.power}.to_json, event: 'messages.create');
      end
    end
    
    if params[:enddate].nil?
      cluster.prosumers.each do |p|
        x = $bunny_channel.fanout("prosumer.#{p.id}")
        q = $bunny_channel.queue("", :exclusive => false)
        q.bind(x)
        puts "Subscribing to: prosumer.#{p.id}"  
        c = q.subscribe(:block => false) do |delivery_info, properties, data|
          sse.write(data, event: 'messages.create')
        end
        consumers.push(c)
      end
    end
    
    loop do
      sleep 10;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end
          
  rescue IOError
  ensure
    consumers.each do |c|
      c.cancel unless c.nil?  
    end unless consumers.nil?
    
    sse.close
    puts "Stream closed."
  end

  def prosumer
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    
    prosumer = Prosumer.find(params[:id])
    startdate = (params[:startdate].nil?) ? (Time.now - 7.days) : params[:startdate].to_time - 1.day
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
    end
  rescue IOError
  ensure
    ActiveRecord::Base.connection.close
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."    
  end

  def realtime
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)

    prosumer = Prosumer.find(params[:id])
    
    startdate = (params[:startdate].nil?) ? (Time.now - 2.days) : params[:startdate].to_time
    enddate = (params[:enddate].nil?) ? (Time.now + 1.days) : params[:enddate].to_time
    
    prosumer.measurements.where(timeslot: startdate..enddate).order(timeslot: :asc).last(200).each do |p|
      sse.write({'id' => p.id, :prosumer_id => prosumer.id, 'X' => p.timeslot.to_i, 'Y' => p.power}.to_json, event: 'messages.create');
    end

    ActiveRecord::Base.connection.close
    
    if params[:enddate].nil?
      x = $bunny_channel.fanout("prosumer.#{params[:id]}")
      q = $bunny_channel.queue("", :exclusive => false)
      q.bind(x)
      puts "Subscribing to: prosumer.#{params[:id]}"
      consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
        sse.write(data, event: 'messages.create')
      end
    end
    loop do
      sleep 10;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end

  rescue IOError
  ensure
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end
end
