require 'streamer/sse'
require 'market/market'

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
    startdate = ((params[:startdate].nil?) ? (DateTime.now - 7.days) : params[:startdate].to_datetime) - 1.day
    enddate = (params[:enddate].nil?) ? (DateTime.now) : params[:enddate].to_datetime
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]
    channel = params[:channel]

    x = $bunny_channel.fanout(channel)
    q = $bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    puts "Subscribing to feed: #{channel}"
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      msg = JSON.parse(data)
      begin
        sse.write(msg['data'].to_json, event: msg['event'])
      rescue IOError => e
        puts e.message
        puts e.backtrace.inspect
        puts "Can't send data to client"
        sse = Streamer::SSE.new(response.stream)
        sse.write(msg['data'].to_json, event: msg['event'])
      end

      ActiveRecord::Base.connection.close
    end

    idata = cluster.request_cached(interval, startdate, enddate, channel)
    idata.each do |d|
      sse.write(d.to_json, event: 'datapoint')
    end

    sse.write(Market::Calculator.new(prosumers: cluster.prosumers,
                                     startDate: startdate,
                                     endDate: enddate).calcCosts.to_json,
              event: 'market')

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
    startdate = ((params[:startdate].nil?) ? (DateTime.now - 7.days) : params[:startdate].to_datetime) - 1.day
    enddate = (params[:enddate].nil?) ? (DateTime.now) : params[:enddate].to_datetime
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]
    channel = params[:channel]

    x = $bunny_channel.fanout(channel)
    q = $bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    puts "Subscribing to: #{channel}"
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      # puts "sending: ", data
      msg = JSON.parse(data)
     #  puts "controller received #{msg}"
      sse.write(msg['data'].to_json, event: msg['event'])
    end

    idata = prosumer.request_cached(interval, startdate, enddate, channel)

    idata.each do |d|
      sse.write(d.to_json, event: 'datapoint')
    end

    sse.write(Market::Calculator.new(prosumers: prosumer,
                                     startDate: startdate,
                                     endDate: enddate).calcCosts.to_json,
              event: 'market')
 
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
      sleep 5;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.connection.close
    end
  rescue => e
    # puts e.message
    # puts e.backtrace
  ensure
    ActiveRecord::Base.connection.close
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end
end
