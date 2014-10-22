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
    consumers = []
    cluster.prosumers.each do |p|
      p.measurements.where(timeslot: (Time.now - 2.days)..(Time.now + 1.day)).order(timeslot: :asc).last(200).each do |m|
        sse.write({:id => m.id, :prosumer_id => p.id, :X => m.timeslot.to_i, :Y => m.power}.to_json, event: 'messages.create');
      end
      x = $bunny_channel.fanout("prosumer.#{p.id}")
      q = $bunny_channel.queue("", :exclusive => false)
      q.bind(x)
  
      c = q.subscribe(:block => false) do |delivery_info, properties, data|
        sse.write(data, event: 'messages.create')
      end
      consumers.push(c)
    end
    
    loop do
      sleep 10;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end
      
  rescue IOError
  ensure
    consumers.each do |c|
      c.cancel unless c.nil?  
    end
    
    sse.close
    puts "Stream closed."
  end

  def realtime
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)

    prosumer = Prosumer.find(params[:id])
    prosumer.measurements.where(timeslot: (Time.now - 2.days)..(Time.now + 1.day)).order(timeslot: :asc).last(200).each do |p|
      sse.write({'id' => p.id, :procumer_id => prosumer.id, 'X' => p.timeslot.to_i, 'Y' => p.power}.to_json, event: 'messages.create');
    end

    ActiveRecord::Base.connection.close

    x = $bunny_channel.fanout("prosumer.#{params[:id]}")
    q = $bunny_channel.queue("", :exclusive => false)
    q.bind(x)

    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      sse.write(data, event: 'messages.create')
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
