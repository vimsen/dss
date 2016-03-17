require 'uri'
require 'open-uri'
require 'json'
require 'yaml'
require 'market/market'
# require 'logger'

module FetchAsynch
  # This class downloads prosumption data from the EDMS, and then inserts them
  # in the DB, and publishes the results to the appropriate rabbitMQ channel.
  class DownloadAndPublish
    def initialize(prosumers, interval, startdate, enddate, channel, async = false)
      @prosumers = prosumers
      @startdate = startdate
      @enddate = enddate
      ActiveRecord::Base.connection_pool.with_connection do
        @interval = Interval.find(interval)
      end

      Rails.logger.debug "Starting new Thread..."
      # Thread.abort_on_exception = true
      thread = Thread.new do
        begin
          ActiveRecord::Base.forbid_implicit_checkout_for_thread!

          i = 0

          x = nil
          begin
            bunny_channel = $bunny.create_channel if channel
            x = bunny_channel.fanout(channel) if channel
          rescue Bunny::Exception # Don't block if channel can't be fanned out
            Rails.logger.debug "Can't fanout channel #{channel}"
            x = nil
          end

          jobs = []

          ActiveRecord::Base.connection_pool.with_connection do

            params = { # prosumers: prosumers.map {|p| p.edms_id}.reject{|id| is_integer? id },
                       startdate: startdate.to_s,
                       enddate: enddate.to_s,
                       interval: @interval.duration }

            new_api_prosumer_ids = prosumers.map {|p| p.edms_id}.reject{|id| is_integer? id }
            old_api_prosumer_ids = prosumers.map {|p| p.edms_id}.select{|id| is_integer? id }


            # Old api jobs
            old_api_prosumer_ids.each_slice(10) do |slice|
              jobs.push params: params.merge(prosumers: slice.join(",")), api: :old
            end

            new_api_prosumer_ids.each do | pr_id |
              # for real data:
              jobs.push params: params.merge(prosumers: pr_id, pointer: 2), api: :new

              # for forecasts:
              ((startdate - 1.day)...enddate).each do | d |
                jobs.push params: params.merge(prosumers: pr_id, pointer: 2, startdate: d, enddate: d + 1.hour), api: :new
              end
            end

          end


          Rails.logger.debug JSON.pretty_generate jobs

          u = YAML.load_file('config/config.yml')[Rails.env]['edms_host']
          rest_resource = RestClient::Resource.new(u)

          Parallel.each(jobs, in_threads: jobs.count) do |job|
            case job[:api]
              when :new
                raw = rest_resource['getdataVGW'].get params: job[:params], :content_type => :json, :accept => :json
                # Rails.logger.debug "RAW: #{raw}"
                result = JSON.parse raw
                Rails.logger.debug "Result: #{result}"
                result_conv = convert_new_to_old_api_v2 result
                #  Rails.logger.debug "Result_conv: #{result_conv}"
                ActiveRecord::Base.connection_pool.with_connection do
                  x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}.", event: "output"}.to_json) if x
                  Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}."
                  datareceived(result_conv, x)
                end
              when :old
                raw = rest_resource['getdata'].get params: job[:params], :content_type => :json, :accept => :json
                result = JSON.parse(raw)
                Rails.logger.debug "Result: #{result}"

                ActiveRecord::Base.connection_pool.with_connection do
                  x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}.", event: "output"}.to_json) if x
                  Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}."
                  datareceived(result, x)
                end
            end
          end


=begin

            if new_api_prosumer_ids.count > 0
              Rails.logger.debug i; i=i+1;
              Rails.logger.debug "Hello"
              new_api_prosumer_ids. each do |id|
                rest_resource = RestClient::Resource.new(u)
                raw = rest_resource['getdataVGW'].get params: params.merge(prosumers: id, pointer: 2)
                # Rails.logger.debug "RAW: #{raw}"
                result = JSON.parse raw
                Rails.logger.debug "Result: #{result}"
                result_conv = convert_new_to_old_api_v2 result
               #  Rails.logger.debug "Result_conv: #{result_conv}"
                x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{id}.", event: "output"}.to_json) if x
                Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{id}."
                datareceived(result_conv, x)
              end
              # datareceived_new(result, channel)
            end

            if old_api_prosumer_ids.count > 0
              Rails.logger.debug i; i=i+1;
              Rails.logger.debug "OLD API"
              uri = URI.parse(u + '/getdata')
              Rails.logger.debug i; i=i+1;

              old_api_prosumer_ids.each_slice(10) do |slice|
                uri.query = URI.encode_www_form(params.merge prosumers: slice.join(","))
                Rails.logger.debug i; i=i+1;

                Rails.logger.debug "In the new Thread..."
                Rails.logger.debug "Connecting to: #{uri}"
                raw = uri.open.read
                #   Rails.logger.debug "RAW: #{raw}"
                result = JSON.parse(raw)
                x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{slice.join(",")}.", event: "output"}.to_json) if x
                Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{slice.join(",")}."
                datareceived(result, x)
              end
            end

          end
=end

          Rails.logger.debug "publshing market data"
          begin
            ActiveRecord::Base.connection_pool.with_connection do
              Rails.logger.debug "Trying to publish market data"
              x.publish({data: Market::Calculator.new(prosumers: @prosumers,
                                                      startDate: @startdate,
                                                      endDate: @enddate).calcCosts,
                         event: 'market'}.to_json) if x
              Rails.logger.debug "publshed market data"
              ActiveRecord::Base.connection_pool.with_connection do
                x.publish({data:  "Interval #{@interval.name}: complete.", event: "output"}.to_json) if x
              end
            end
            Rails.logger.debug "pushed end message"
          rescue Bunny::Exception # Don't block if channel can't be fanned out
            Rails.logger.debug "Can't publish to channel #{channel}"
          end
          Rails.logger.debug "market data published."
          Rails.logger.debug 'done'
        rescue => e
          Rails.logger.debug "EXCEPTION: #{e.inspect}"
          puts "EXCEPTION: #{e.inspect}"
          Rails.logger.debug "MESSAGE: #{e.message}"
          puts "MESSAGE: #{e.message}"
          Rails.logger.debug e.backtrace.join("\n")
          puts e.backtrace.join("\n")
        end
      end

      thread.join if (async)


    end

    private

    def is_integer?(num)
      !!(num =~ /\A[-+]?[0-9]+\z/)
    end

    def newAPI?(prosumers)
      ActiveRecord::Base.connection_pool.with_connection do
        Rails.logger.debug "AAAAAAAAAAAAAAAAAAAAAAAAAAA"
        prosumers.reject {|p| is_integer?(p.edms_id) }.count > 0
      end
    end

    def convert_new_to_old_api(data)
      data.map do |d|
        {
            "timestamp" => d["Date"],
            "procumer_id" => d["Mac"],
            "interval" => @interval.duration,
            "actual" => {
                "production" => nil,
                "consumption" => d["Kwh"],
                "storage" => nil
            },
            "forecast" => {
                "timestamp" => "",
                "production" => nil,
                "consumption" => nil,
                "storage" => nil
            },
            "dr" => nil,
            "reliability" => nil
        } if is_integer? d["Kwh"].to_s
      end.compact
    end

    def hash_to_key_value(hash)
      key, value = hash.first
      [
          DateTime.parse(key).to_s,
          value.scan(/\d+[,.]?\d?/).first.gsub(/,/, ".").to_f
      ]
    end

    def empty_data_point_object(timestamp)
      {
          "timestamp" => timestamp,
          "procumer_id" => nil,
          "interval" => @interval.duration,
          "actual" => {
              "production" => nil,
              "consumption" => nil,
              "storage" => nil
          },
          "forecast" => {
              "timestamp" => "",
              "production" => nil,
              "consumption" => nil,
              "storage" => nil
          },
          "dr" => nil,
          "reliability" => nil
      }
    end

    def convert_new_to_old_api_v2(data)

      intermediate_data = {}
      result = data.first
      Rails.logger.debug JSON.pretty_generate result
      result["Production"].map(&method(:hash_to_key_value)).each do | key,value |
        intermediate_data[key] ||= empty_data_point_object key
        intermediate_data[key]["procumer_id"] = result["ProsumerId"]
        intermediate_data[key]["actual"]["production"] = value
      end
      result["Storage"].map(&method(:hash_to_key_value)).each do | key,value |
        intermediate_data[key] ||= empty_data_point_object key
        intermediate_data[key]["procumer_id"] = result["ProsumerId"]
        intermediate_data[key]["actual"]["storage"] = value
      end
      result["Consumption"].map(&method(:hash_to_key_value)).each do | key,value |
        intermediate_data[key] ||= empty_data_point_object key
        intermediate_data[key]["procumer_id"] = result["ProsumerId"]
        intermediate_data[key]["actual"]["consumption"] = value
      end
      result["ForecastConsumption"].map(&method(:hash_to_key_value)).each do | key,value |
        timestamp = DateTime.parse(key) - 24.hours
        intermediate_data[timestamp] ||= empty_data_point_object timestamp
        intermediate_data[timestamp]["procumer_id"] = result["ProsumerId"]
        intermediate_data[timestamp]["forecast"]["consumption"] = value
        intermediate_data[timestamp]["forecast"]["timestamp"] = DateTime.parse(key)
      end
      result["ForecastProduction"].map(&method(:hash_to_key_value)).each do | key,value |
        timestamp = DateTime.parse(key) - 24.hours
        intermediate_data[timestamp] ||= empty_data_point_object timestamp
        intermediate_data[timestamp]["procumer_id"] = result["ProsumerId"]
        intermediate_data[timestamp]["forecast"]["production"] = value
        intermediate_data[timestamp]["forecast"]["timestamp"] = DateTime.parse(key)
      end
      Rails.logger.debug JSON.pretty_generate intermediate_data
      intermediate_data.values
    end

    def datareceived(data, x)

      Rails.logger.debug "Finding existing datapoints"
      new_data_points = []
      procs = []

      Upsert.logger = Logger.new("/dev/null")

      ActiveRecord::Base.connection_pool.with_connection do | conn |
        procs = Hash[@prosumers.map {|p| [p.edms_id, p]}]

        begin
          upsert_status = Upsert.batch(conn, DataPoint.table_name) do |upsert|
            data.each do | d |
              # puts "Data Point: #{d}"
              upsert.row({
                             timestamp: d['timestamp'].to_datetime,
                             prosumer_id: procs[d['procumer_id'].to_s].id,
                             interval_id: @interval.id
                         }, {
                             production: d['actual']['production'],
                             consumption: d['actual']['consumption'],
                             storage: d['actual']['storage'],
                             f_timestamp: d['forecast']['timestamp'].to_datetime,
                             f_production: d['forecast']['production'],
                             f_consumption: d['forecast']['consumption'],
                             f_storage: d['forecast']['storage'],
                             dr: d['dr'],
                             reliability: d['reliability']
                         }
              ) if valid_time_stamp d['timestamp']
            end
          end
          x.publish({data:  "Interval #{@interval.name}: UPSERT status: #{upsert_status.count}", event: "output"}.to_json) if x
          Rails.logger.debug "Interval #{@interval.name}: UPSERT status: #{upsert_status.count}"
        rescue PG::InvalidTextRepresentation => e
          x.publish({data:  "Interval #{@interval.name}: BAD DATA FORMAT: #{upsert_status}", event: "output"}.to_json)
          # x.publish({data:  "BAD DATA FORMAT: #{data}", event: "output"}.to_json)
          Rails.logger.debug "Interval #{@interval.name}: BAD DATA FORMAT: #{upsert_status}"
          # Rails.logger.debug "BAD DATA FORMAT: #{data}"
          raise e
        end




        new_data_points = data.reject do |d|
          !valid_time_stamp(d['timestamp']) || d['timestamp'].to_datetime.future?
        end

      end

      begin
        message = new_data_points.map do |d|
          prepare(d, procs)
        end
        x.publish({data: message, event: 'datapoints'}.to_json) unless x.nil?
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't publish to channel #{channel}"
      ensure
      end
    end

    def db_prepare(d, procs)
     DataPoint.new(
        timestamp: d['timestamp'].to_datetime,
        prosumer: procs[d['procumer_id'].to_s],
        interval: @interval,
        production: d['actual']['production'],
        consumption: d['actual']['consumption'],
        storage: d['actual']['storage'],
        f_timestamp: d['forecast']['timestamp'].to_datetime,
        f_production: d['forecast']['production'],
        f_consumption: d['forecast']['consumption'],
        f_storage: d['forecast']['storage'],
        dr: d['dr'],
        reliability: d['reliability']
     )
    end

    def prepare(d, procs)
      k = d.deep_dup

      k['timestamp'] = d['timestamp'].to_datetime.to_i
      k['prosumer_id'] = procs[d['procumer_id'].to_s].id
      k['prosumer_name'] = procs[d['procumer_id'].to_s].name
      k['forecast']['timestamp'] =
          d['forecast']['timestamp'].to_datetime.to_i
      return k
    end

    def valid_time_stamp(str)
      Time.iso8601(str.to_s)
      return true
    rescue ArgumentError => e
      Rails.logger.debug "Received junk input: #{str}"
      return false
    end
  end
end
