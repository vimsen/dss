require 'streamer/sse'
require 'market/market'
require 'clustering/match_expected'
require 'fetch_asynch/download_and_publish'

class StreamController < ApplicationController
  include ActionController::Live

  def demand_response
    response.headers['Content-Type'] = 'text/event-stream'
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    sse = Streamer::SSE.new(response.stream)
    dr_id = params[:id]

    loop do
      begin
        ActiveRecord::Base.connection_pool.with_connection do
          sse.write(DemandResponse.find(dr_id).request_cached(nil).to_json, event: 'messages.demand_response_data')
        end
      rescue RestClient::Exception, Errno::ECONNREFUSED => e
        sse.write("Failed to connect to GDRMS".to_json, event: 'messages.gdrms_unavailable')
        reachable = false
      end
      ActiveRecord::Base.clear_active_connections!
      sleep 30;
    end

  rescue IOError, ActionController::Live::ClientDisconnected
  ensure
    ActiveRecord::Base.clear_active_connections!
    sse.close
    puts "Stream closed."
  end


  def clusterfeed
    response.headers['Content-Type'] = 'text/event-stream'
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    sse = Streamer::SSE.new(response.stream)
    
    cluster = Cluster.find(params[:id])
    startdate = ((params[:startdate].nil?) ? (DateTime.now - 7.days) : params[:startdate].to_datetime)
    enddate = (params[:enddate].nil?) ? (DateTime.now) : params[:enddate].to_datetime
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]
    channel = params[:channel]
    type = (params[:type].nil? ? :prosumption : params[:type])
    forecast = (params[:forecast].nil? ? :none : params[:forecast])

    session[:startdate] = startdate
    session[:enddate] = enddate
    session[:interval] = interval
    session[:type] = type
    session[:forecast] = forecast


    ActiveRecord::Base.clear_active_connections!
    bunny_channel = $bunny.create_channel
    x = bunny_channel.fanout(channel)
    q = bunny_channel.queue("", :exclusive => false)
    q.bind(x)

    ActiveRecord::Base.clear_active_connections!
    puts "Subscribing to feed: #{channel}"
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      begin
        msg = JSON.parse(data)
        # puts "Stream Controller received: #{msg['event']},\ndata: #{msg['data']}"

        # puts JSON.pretty_generate msg
        if msg['event'] == 'datapoints'
          msg['data'].each do |d|
            sse.write(d.to_json, event: 'datapoint')
            ActiveRecord::Base.clear_active_connections!
          end
        else
          sse.write(msg['data'].to_json, event: msg['event'])
        end
      rescue IOError
        puts "I should NOT be here!"
        consumer.cancel unless consumer.nil?
        sse.close
        puts "Stream closed2."
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end

    idata = cluster.request_cached(interval, startdate - 1.day, enddate, channel)
    idata[:data_points].each do |d|
      sse.write(d.to_json, event: 'datapoint')
    end

    sse.write(idata[:fms].to_json, event: 'fms_data')

    ActiveRecord::Base.clear_active_connections!
    sse.write(Market::Calculator.new(prosumers: cluster.prosumers,
                                     startDate: startdate - 1.day,
                                     endDate: enddate).calcCosts.to_json,
              event: 'market')

    ActiveRecord::Base.clear_active_connections!
    
    loop do
      sleep 1;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.clear_active_connections!
    end
          
  rescue IOError, ActionController::Live::ClientDisconnected
  ensure
    ActiveRecord::Base.clear_active_connections!
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end

  def prosumer
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    
    prosumer = Prosumer.find(params[:id])
    startdate = ((params[:startdate].nil?) ? (DateTime.now - 7.days) : params[:startdate].to_datetime)
    enddate = (params[:enddate].nil?) ? (DateTime.now) : params[:enddate].to_datetime
    interval = (params[:interval].nil?) ? Interval.find(3).id : params[:interval]
    channel = params[:channel]
    type = (params[:type].nil? ? :prosumption : params[:type])
    forecast = (params[:forecast].nil? ? :none : params[:forecast])

    puts "Data for #{startdate} .. #{enddate}"

    session[:startdate] = startdate
    session[:enddate] = enddate
    session[:interval] = interval
    session[:type] = type
    session[:forecast] = forecast

    ActiveRecord::Base.clear_active_connections!
    bunny_channel = $bunny.create_channel
    x = bunny_channel.fanout(channel)
    q = bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    ActiveRecord::Base.clear_active_connections!
    puts "Subscribing to: #{channel}"
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      # puts "sending: ", data
      begin
        msg = JSON.parse(data)

        # puts JSON.pretty_generate msg
        if msg['event'] == 'datapoints'
          msg['data'].each do |d|
            sse.write(d.to_json, event: 'datapoint')
            ActiveRecord::Base.clear_active_connections!
          end
        else
          sse.write(msg['data'].to_json, event: msg['event'])
        end
      rescue IOError
        consumer.cancel unless consumer.nil?
        sse.close
        puts "Stream closed2."
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end

    idata = prosumer.request_cached(interval, startdate - 1.day, enddate, channel)

    idata[:data_points].each do |d|
      sse.write(d.to_json, event: 'datapoint')
    end

    sse.write(idata[:fms].to_json, event: 'fms_data')

    ActiveRecord::Base.clear_active_connections!
    sse.write(Market::Calculator.new(prosumers: [prosumer],
                                     startDate: startdate - 1.day,
                                     endDate: enddate).calcCosts.to_json,
              event: 'market')
 
    ActiveRecord::Base.clear_active_connections!
    
    loop do
      ActiveRecord::Base.clear_active_connections!
      sleep 1;
      ActiveRecord::Base.connection_pool.with_connection do
        sse.write("OK".to_json, event: 'messages.keepalive')
      end
    end
  rescue IOError, ActionController::Live::ClientDisconnected
  ensure
    ActiveRecord::Base.clear_active_connections!
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."    
  end

  def meter
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    meter = Meter.find(params[:id])


    bunny_channel = $bunny.create_channel
    x = bunny_channel.topic("imeter_exchange")
    q = bunny_channel.queue("", :auto_delete => false).bind(x, :routing_key => "imeter.data.#{meter.mac}")
    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      # puts "sending: ", data
      # puts delivery_info, properties, data
      t = DateTime.parse(JSON.parse(data)["t"]).to_i
      p = JSON.parse(data)["kw"]
      sse.write( { timestamp: t,
                   actual: {
                     kw: p
                    }}.to_json, event: 'datapoint')
    end
    puts "subscribed"

    ActiveRecord::Base.clear_active_connections!

    loop do
      sleep 5;
      sse.write("OK".to_json, event: 'messages.keepalive')
      ActiveRecord::Base.clear_active_connections!
    end
  rescue ActionController::Live::ClientDisconnected => e
    # puts e.message
    # puts e.backtrace
  ensure
    ActiveRecord::Base.clear_active_connections!
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end

  def download_data
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)

    bunny_channel = $bunny.create_channel
    channel_name = SecureRandom.uuid
    x = bunny_channel.fanout(channel_name)
    q = bunny_channel.queue("", :exclusive => false)
    q.bind(x)
    remaining = 0

    sse.write("Downloading data. Please wait...".to_json, event: 'output')

    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
      begin
        msg = JSON.parse(data)
        if msg['event'] == "output"

          remaining = remaining - 1 if msg['data'] =~ %r{^Interval.*: complete\.$}
         #  puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", delivery_info, properties, data
         #  puts "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY", msg
          sse.write(msg['data'].to_json, event: msg['event'])

        end
      rescue IOError
        consumer.cancel unless consumer.nil?
        sse.close
        puts "Stream closed2."
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end

    startdate = DateTime.now - 2.weeks
    enddate = DateTime.now

    remaining = 2
    # FetchAsynch::DownloadAndPublish.new(Prosumer.all, 1, startdate, enddate, channel_name)
    FetchAsynch::DownloadAndPublish.new prosumers: Prosumer.real_time,
                                        interval: 2,
                                        startdate: startdate,
                                        enddate: enddate,
                                        channel: channel_name

    FetchAsynch::DownloadAndPublish.new prosumers: Prosumer.real_time,
                                        interval: 3,
                                        startdate: startdate,
                                        enddate: enddate,
                                        channel: channel_name

    until remaining == 0
      sleep 1;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end

    sse.write("done".to_json, event: 'result')
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed3."


  rescue IOError, ActionController::Live::ClientDisconnected
  ensure
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end


  def run_algorithm
    ActiveRecord::Base.forbid_implicit_checkout_for_thread!
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)

   #  puts "PARAMS: #{params[:targets]}"

    bunny_channel = $bunny.create_channel
    channel_name = SecureRandom.uuid
    x = bunny_channel.fanout(channel_name)
    q = bunny_channel.queue("", :exclusive => false)
    q.bind(x)

    consumer = q.subscribe(:block => false) do |delivery_info, properties, data|
       puts "Received: ", data
      begin
        msg = JSON.parse(data)
        sse.write(msg['data'].to_json, event: msg['event'])
      rescue IOError
        consumer.cancel unless consumer.nil?
        sse.close
        puts "Stream closed2."
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end

    Thread.new do
      begin
        ActiveRecord::Base.forbid_implicit_checkout_for_thread!
        ActiveRecord::Base.connection_pool.with_connection do
          puts "Running algorithm"
          tm = ClusteringModule::TargetMatcher.new(
              prosumers: Prosumer.where(prosumer_category: params[:prosumer_category_id]),
              startDate: DateTime.parse(params[:startDate]),
              endDate: DateTime.parse(params[:endDate]),
              interval: params[:interval].to_i,
              targets: JSON.parse(params[:targets]).map{|v| v[1]},
              rb_channel: channel_name,
              download: params[:download] == "none" ? nil : params[:download].to_sym
          )
          puts "Object created"
          results = tm.run
          sse.write(results.to_json, event: "result")

          puts JSON.pretty_generate results

        end
      rescue => e
        Rails.logger.debug e
        Rails.logger.debug e.backtrace.join("\n")
      end
    end

    loop do
      sleep 1;
      sse.write("OK".to_json, event: 'messages.keepalive')
    end
  rescue IOError, ActionController::Live::ClientDisconnected
  ensure
    consumer.cancel unless consumer.nil?
    sse.close
    puts "Stream closed."
  end


end
