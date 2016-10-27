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
    def initialize(prosumers, interval, startdate, enddate, channel, async = false, forecasts = true)
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

            new_api_prosumer_ids = prosumers.map {|p| p.edms_id}.select{|id| newAPI? id }
            old_api_prosumer_ids = prosumers.map {|p| p.edms_id}.reject{|id| newAPI? id }


            # Old api jobs
            old_api_prosumer_ids.each_slice(10) do |slice|
              jobs.push params: params.merge(prosumers: slice.join(",")), api: :old
            end

            new_api_prosumer_ids.each do | pr_id |

              thresh = Date.today.beginning_of_day.to_datetime

              #Ugly hack because Jiannis cant handle caching properly
            #  if startdate < thresh && thresh < enddate
            #    jobs.unshift params: params.merge(prosumers: pr_id, pointer: 2, startdate: startdate.to_s, enddate: thresh.to_s), api: :new
            #    jobs.unshift params: params.merge(prosumers: pr_id, pointer: 2, startdate: thresh.to_s, enddate: enddate.to_s), api: :new
            #  else
                # for real data:
                jobs.unshift params: params.merge(prosumers: pr_id, pointer: 2), api: :new
            #  end


              # for forecasts:

            # Deleted until forecasts are fixed, no point requesting stugff we don't get
              if forecasts
                 ((startdate - 1.day)...enddate).each do | d |
                   jobs.push params: params.merge(prosumers: pr_id, pointer: 2, startdate: d, enddate: d + 1.hour), api: :new
                 end
              end
            end

            # Try to download everything from FMS
            if forecasts
              prosumers.map {|p| p.edms_id}.each do |pr_id|
                ((startdate - 1.day)...enddate).each do | d |
                  d_start = d.beginning_of_day
                  d_end = d.end_of_day
                  d_forc = d_start - 12.hours
                  jobs.push params: params.merge(prosumers: pr_id, startdate: d_start, enddate: d_end, forecasttime: d_forc), api: :fms
                end
              end
            end
          end


          # Rails.logger.debug JSON.pretty_generate jobs

          u = YAML.load_file('config/vimsen_hosts.yml')[Rails.env]
          edms_rest_resource = RestClient::Resource.new u['edms_host'] #, verify_ssl: OpenSSL::SSL::VERIFY_NONE
          fms_rest_resource = RestClient::Resource.new u['fms_host'], verify_ssl: OpenSSL::SSL::VERIFY_NONE

          Parallel.each(jobs, in_threads: 3) do |job|
            begin
              case job[:api]
                when :new
                  raw = edms_rest_resource['getdataVGW'].get params: job[:params], :content_type => :json, :accept => :json
                  # Rails.logger.debug "RAW: #{raw}"
                  result = JSON.parse raw
                  # Rails.logger.debug "Result: #{result}"
                  result_conv = convert_new_to_old_api_v2 result, job[:params][:prosumers]
                  #  Rails.logger.debug "Result_conv: #{result_conv}"
                  ActiveRecord::Base.connection_pool.with_connection do
                    x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}.", event: "output"}.to_json) if x
                    Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}."
                  end
                  datareceived(result_conv, x)

                when :fms
                  puts "=-=================== FSM: #{job[:params]} =-=================== "
                  # raw = fms_rest_resource['fmsapt'].get params: job[:params], :content_type => :json, :accept => :json
                  # result = JSON.parse raw
                  # datareceived_fms(result, x)

                when :old
                  raw = edms_rest_resource['getdata'].get params: job[:params], :content_type => :json, :accept => :json
                  result = JSON.parse(raw)
                # Rails.logger.debug "Result: #{result}"

                  ActiveRecord::Base.connection_pool.with_connection do
                    x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}.", event: "output"}.to_json) if x
                    Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}."
                    end
                  datareceived(result, x)
              end
            rescue Exception => e
              Rails.logger.debug "EXCEPTION: #{e.inspect}"
              puts "EXCEPTION: #{e.inspect}"
              Rails.logger.debug "MESSAGE: #{e.message}"
              puts "MESSAGE: #{e.message}"
              Rails.logger.debug e.backtrace.join("\n")
              puts e.backtrace.join("\n")
            end
          end

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

    def datareceived_fms(data, x)
      Rails.logger.debug data
    end


    def is_integer?(num)
      !!(num =~ /\A[-+]?[0-9]+\z/)
    end

    def newAPI?(id)
      ActiveRecord::Base.connection_pool.with_connection do
        (! is_integer?(id)) || (id.to_i > 100)
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
          # DateTime.parse(key).to_s,
          key,
          value.scan(/-?\d+[,.]?\d*/).first.gsub(/,/, ".").to_f
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

    def validate_timestamp(timestamp)

      case @interval.duration
        when 900
          timestamp.to_datetime.to_i % 900 == 0
        when 3600
          timestamp.to_datetime.to_i % 3600 == 0
        when 86400
          (DateTime.parse(timestamp).beginning_of_day + Time.zone.parse(timestamp).utc_offset.seconds) == (DateTime.parse(timestamp))
      end
    end

    def validate_value(value)

      return true # Some values are just too large

      case @interval.duration
        when 900
          value < 500
        when 3600
          value < 2000
        when 86400
          value < 30000
      end
    end

    def parse_vals(result, intermediate_data, edms_key)
      return if result[edms_key].nil?
      result[edms_key].map(&method(:hash_to_key_value)).each do | key,value |
        if validate_value(value) && validate_timestamp(key)
          intermediate_data[key] ||= empty_data_point_object key
          intermediate_data[key]["procumer_id"] = result["ProsumerId"]
          res  = value.nil? ? nil : value.to_f
          case edms_key
            when "Production"
              intermediate_data[key]["actual"]["production"] = res
            when "Storage"
              intermediate_data[key]["actual"]["storage"] = res
            when "Consumption"
              intermediate_data[key]["actual"]["consumption"] = res
            when "Flexibility"
              intermediate_data[key]["dr"] = res unless @interval.duration == 86400
            when "Reliability"
              intermediate_data[key]["reliability"] = res unless @interval.duration == 86400
          end
        end
      end
    end

    def is_valid_iso8601(timestamp)
      begin
        Time.iso8601 timestamp
        return true
      rescue ArgumentError => e
        return false
      end
    end


    def convert_new_to_old_api_v2(data, prosumer)

      intermediate_data = {}
      result = data.first

      result["ProsumerId"] = prosumer if result["ProsumerId"].nil? || result["ProsumerId"] == ""

      Rails.logger.debug result

      %w[Production Storage Consumption Flexibility Reliability].each do |key|
        parse_vals result, intermediate_data, key
      end

      result["ForecastConsumption"].map(&method(:hash_to_key_value)).each do | key,value |

        key=key
        puts "@@@@@@@@@@@@@@@@@@@ #{key.to_s}"
        if @interval.duration == 86400 && !is_valid_iso8601(key)
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = key.to_datetime.change(:offset => "+0200").to_s
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = (DateTime.parse(key).beginning_of_day + Time.zone.parse(key).utc_offset.seconds).to_s
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
        end

        timestamp = case @interval.duration
                      when 900
                        DateTime.parse(key) - 24.hours
                      when 3600
                        (DateTime.parse(key) - 24.hours).beginning_of_hour
                      when 86400
                        DateTime.parse(key).utc_offset == 7200 ? # Reject wrong timezones
                            (DateTime.parse(key) - 24.hours).beginning_of_day + Time.zone.parse(key).utc_offset.seconds :
                            nil
                    end
        # Rails.logger.debug "ForecastConsumption: #{key}: #{DateTime.parse(key) - 24.hours} --- #{timestamp}"

        if timestamp && validate_value(value)
          intermediate_data[timestamp] ||= empty_data_point_object timestamp
          intermediate_data[timestamp]["procumer_id"] = result["ProsumerId"]
          intermediate_data[timestamp]["forecast"]["consumption"] ||= 0
          intermediate_data[timestamp]["forecast"]["consumption"] += value.to_f unless value.nil?
          intermediate_data[timestamp]["forecast"]["timestamp"] = timestamp + 24.hours
          # puts "-------------> time: #{timestamp}  inter: #{intermediate_data[timestamp]["forecast"]["consumption"]}"
        end
      end if result["ForecastConsumption"].length > 0

      result["ForecastProduction"].map(&method(:hash_to_key_value)).each do | key,value |

        key=key
        puts "@@@@@@@@@@@@@@@@@@@ #{key.to_s}"
        if @interval.duration == 86400 && !is_valid_iso8601(key)
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = key.to_datetime.change(:offset => "+0200").to_s
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = (DateTime.parse(key).beginning_of_day + Time.zone.parse(key).utc_offset.seconds).to_s
          puts "@@@@@@@@@@@@@@@@@@@ #{key}"
        end

        timestamp = case @interval.duration
                      when 900
                        DateTime.parse(key) - 24.hours
                      when 3600
                        (DateTime.parse(key) - 24.hours).beginning_of_hour
                      when 86400
                        DateTime.parse(key).utc_offset == 7200 ? # Reject wrong timezones
                            (DateTime.parse(key) - 24.hours).beginning_of_day + Time.zone.parse(key).utc_offset.seconds :
                            nil
                    end
        # Rails.logger.debug "ForecastProduction: #{key}: #{DateTime.parse(key) - 24.hours} --- #{timestamp}, #{DateTime.parse(key).utc_offset}"

        if timestamp && validate_value(value)
          intermediate_data[timestamp] ||= empty_data_point_object timestamp
          intermediate_data[timestamp]["procumer_id"] = result["ProsumerId"]
          intermediate_data[timestamp]["forecast"]["production"] ||= 0
          intermediate_data[timestamp]["forecast"]["production"] += value.to_f unless value.nil?
          intermediate_data[timestamp]["forecast"]["timestamp"] = timestamp + 24.hours
          # puts "-------------> time: #{timestamp}  inter: #{intermediate_data[timestamp]["forecast"]["production"]}"
        end

      end if result["ForecastProduction"].length > 0

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

              if procs[d['procumer_id'].to_s]
                # puts "Received: #{d}"
                selector = {
                    timestamp: d['timestamp'].to_datetime,
                    prosumer_id: procs[d['procumer_id'].to_s].id,
                    interval_id: @interval.id
                }

                setter = {
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

                setter.reject!{|k,v| v.nil?}

                upsert.row(selector, setter) if valid_time_stamp d['timestamp']
              end
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
        end.compact
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

      if procs[d['procumer_id'].to_s]
        k = d.deep_dup

        k['timestamp'] = d['timestamp'].to_datetime.to_i
        k['prosumer_id'] = procs[d['procumer_id'].to_s].id
        k['prosumer_name'] = procs[d['procumer_id'].to_s].name
        k['forecast']['timestamp'] =
            d['forecast']['timestamp'].to_datetime.to_i
        k['actual']['prosumption'] = prosumption(d['actual']['consumption'], d['actual']['production'])
        k['forecast']['prosumption'] = prosumption(d['forecast']['consumption'], d['forecast']['production'])
        return k
      else
        return nil
      end
    end

    def prosumption(consumption, production)
      return nil if consumption.nil? && production.nil?
      consumption.to_f - production.to_f
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
