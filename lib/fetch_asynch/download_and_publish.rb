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
    def initialize(prosumers: Prosumer.real_time,
                   interval: 3,
                   startdate: DateTime.now - 1.week,
                   enddate: DateTime.now,
                   channel: nil,
                   async: false,
                   forecasts: "none",
                   only_missing: false,
                   threads: 2)
      @prosumers = prosumers
      @startdate = startdate
      @enddate = enddate
      ActiveRecord::Base.connection_pool.with_connection do
        @interval = Interval.find(interval)
        @prosumer_reverse_hash = @prosumers.map{|p| [p.edms_id, {id: p.id, name: p.name}]}.to_h
      end

      Upsert.logger = Logger.new("/dev/null")

      Rails.logger.debug "Starting new Thread..."

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
            Rails.logger.debug "startdate: #{startdate}, enddate: #{enddate}"
            max_points = ((enddate.to_f - startdate.to_f) / @interval.duration.seconds).to_i
            max_forc = (1.day / @interval.duration.seconds).to_i
            real_data_points_in_db = DataPoint
                                         .joins(:prosumer)
                                         .where(prosumer: prosumers, timestamp: startdate .. enddate, interval: @interval)
                                         .where('? IS NOT NULL OR ? IS NOT NULL', :production, :consumption)
                                         .group('prosumers.edms_id')
                                         .count if only_missing
            forecast_data_points_in_db = DataPoint
                                             .joins(:prosumer)
                                             .where(prosumer: prosumers, timestamp: startdate .. enddate, interval: @interval)
                                             .where('? IS NOT NULL OR ? IS NOT NULL', :f_production, :f_consumption)
                                             .group('prosumers.edms_id', 'date(timestamp)')
                                             .count if forecasts == "edms" && only_missing


            Rails.logger.debug "----------------------------------------------------------- #{forecasts}, #{only_missing}"

            params = { # prosumers: prosumers.map {|p| p.edms_id}.reject{|id| is_integer? id },
                       startdate: startdate.to_s,
                       enddate: enddate.to_s,
                       interval: @interval.duration }

            new_api_prosumer_ids = prosumers.map {|p| p.edms_id}.select{|id| newAPI? id }
            old_api_prosumer_ids = prosumers.map {|p| p.edms_id}.reject{|id| newAPI? id }

            old_api_prosumer_ids.select!{|p| real_data_points_in_db[p].nil? || real_data_points_in_db[p] < max_points } if only_missing

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

              if !only_missing || real_data_points_in_db[pr_id].nil? || real_data_points_in_db[pr_id] < max_points
                # Rails.logger.debug "#{pr_id}:  points: #{real_data_points_in_db[pr_id] rescue 0}, we want: #{max_points} "
                jobs.unshift params: params.merge(prosumers: pr_id, pointer: 2, consumptionFlag: dont_divide(pr_id)), api: :new, forc: false
              end


              # for forecasts:

            # Deleted until forecasts are fixed, no point requesting stugff we don't get
              if forecasts == "edms"
                 ((startdate - 1.day)...enddate).each do | d |
                   if !only_missing || forecast_data_points_in_db[[pr_id, d.to_date]].nil? || forecast_data_points_in_db[[pr_id, d.to_date]] < max_forc
                     jobs.push params: params.merge(prosumers: pr_id, pointer: 2, startdate: d, enddate: d + 1.hour), api: :new, forc: true
                   end
                 end
              end
            end


            # Try to download everything from FMS
            # puts "==================forecast:  #{forecasts}, interval: #{interval}, #{forecasts == "FMS-D"}, #{[1,2].include?(interval)}"
            # Rails.logger.debug "points: #{fms_forecasts_in_db rescue 0}, we want: #{max_points} "

            if forecasts == "FMS-D" && [1,2].include?(interval)
              puts "I'm in !!! #{prosumers}"
              ((startdate - 1.day)...enddate).each do | d |
                db = d.utc.beginning_of_day
                int_end = db
                begin
                  int_start = int_end
                  max_prosumer_batch = 5
                  int_end = [int_start + ((499 / max_prosumer_batch) * @interval.duration).seconds, db + 1.day].min

                  fms_forecasts_in_db = Forecast
                                            .joins(:prosumer)
                                            .where(prosumer: prosumers, timestamp: int_start .. int_end, interval: @interval, forecast_type: 0)
                                            .where('? IS NOT NULL OR ? IS NOT NULL', :production, :consumption)
                                            .group('prosumers.edms_id')
                                            .count if only_missing

                  prosumers.select{|p| p.prosumer_category_id == 4}.map {|p| p.edms_id}.sort.each_slice(max_prosumer_batch) do |pr_v|
                    pr_id = pr_v.join(",")

                    # Rails.logger.debug "#{pr_id}:  points: #{fms_forecasts_in_db[pr_id] rescue 0}, we want: #{max_points} "
                    max_points = pr_v.size * ((int_end.to_f - int_start .to_f) / @interval.duration.seconds).to_i

                    if !only_missing || (fms_forecasts_in_db[pr_id] || 0) < max_points
                      jobs.unshift params: params.merge(prosumers: pr_id, startdate: int_start, enddate: int_end, forecasttime: (db -1.day).middle_of_day, forecasttype: "DayAhead", aggregate: false), api: :fms
                    end

                    # jobs.unshift params: params.merge(prosumers: pr_id, startdate: startdate, enddate: enddate, forecasttime: startdate.beginning_of_day + 9.hours, forecasttype: "IntraDay", aggregate: true), api: :fms
                  end
                end while int_end < db + 1.day
              end
            end
          end

          # Rails.logger.debug JSON.pretty_generate jobs

          u = YAML.load_file('config/vimsen_hosts.yml')[Rails.env]
          edms_rest_resource = RestClient::Resource.new u['edms_host'] #, verify_ssl: OpenSSL::SSL::VERIFY_NONE
          fms_rest_resource = RestClient::Resource.new u['fms_host'], verify_ssl: OpenSSL::SSL::VERIFY_NONE

          # Rails.logger.debug "The jobs queue is #{JSON.pretty_generate jobs}"

          Parallel.each(jobs, in_threads: threads) do |job|
            begin
              # sleep 1
              case job[:api]
                when :new
                  raw = edms_rest_resource['getdataVGW'].get params: job[:params], :content_type => :json, :accept => :json
                  # Rails.logger.debug "RAW: #{raw}"
                  result = JSON.parse raw
                  # Rails.logger.debug "Result: #{result}"
                  result_conv = convert_new_to_old_api_v2 result, job[:params][:prosumers], job[:forc]
                  #  Rails.logger.debug "Result_conv: #{result_conv}"
                  ActiveRecord::Base.connection_pool.with_connection do
                    x.publish({data:  "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}.", event: "output"}.to_json) if x
                    Rails.logger.debug "Interval #{@interval.name}: Processing results for prosumers: #{job[:params][:prosumers]}."
                  end
                  datareceived(result_conv, x)

                when :fms
                  # puts "=-=================== FSM: #{job[:params]} =-=================== "
                  raw = fms_rest_resource['fmsapt'].get params: job[:params], :content_type => :json, :accept => :json
                  result = JSON.parse raw
                  datareceived_fms(result, x)

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
                                                      endDate: @enddate).calcCosts2,
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
      # Rails.logger.debug data

      received_prosumers = {}
      min_ts = @enddate
      max_ts = @startdate


      ActiveRecord::Base.connection_pool.with_connection do | conn |
        begin
          upsert_status = Upsert.batch(conn, Forecast.table_name) do |upsert|
            data["items"].each do | item |

              # ts = item['timestamp'].sub(/:0.$/,'00').to_datetime - ([20001..20033, 20089..20124].any? {|r| r.cover? @prosumer_reverse_hash[item['prosumer_id'].to_s][:id]} ? 3.hours : (@interval.id == 2? 1.hour: 0.hour))

              ts_received = item['timestamp'].to_datetime

              ts_cons = ts_received # - (ts_received.to_time.dst? ? (@interval.id == 2? 3.hour: 4.hour) : (@interval.id == 2? 1.hour: 2.hour))# - 3.hour
              ts_prod = ts_received - (ts_received.to_time.dst? ? (@interval.id == 2? 3.hour: 4.hour) : (@interval.id == 2? 1.hour: 2.hour))# - 3.hour

              min_ts = [ts_cons, ts_prod, min_ts].min
              max_ts = [ts_cons, ts_prod, max_ts].max

              if @prosumer_reverse_hash[item['prosumer_id'].to_s] && validate_timestamp(ts_cons)
                # puts "Received: #{d}"
                received_prosumers[@prosumer_reverse_hash[item['prosumer_id'].to_s][:id]] = 1
                selector = {
                    timestamp: ts_cons,
                    prosumer_id: @prosumer_reverse_hash[item['prosumer_id'].to_s][:id],
                    interval_id: @interval.id,
                    forecast_time: nil,
                    forecast_type: 0
                }

                setter = {
                    consumption: item['f_consumption'],
                    storage: item['f_storage'],
                    created_at: DateTime.now,
                    updated_at: DateTime.now
                }

                setter.reject!{|k,v| v.nil?}

                upsert.row(selector, setter)
              end
              if @prosumer_reverse_hash[item['prosumer_id'].to_s] && validate_timestamp(ts_prod)
                # puts "Received: #{d}"
                received_prosumers[@prosumer_reverse_hash[item['prosumer_id'].to_s][:id]] = 1
                selector = {
                    timestamp: ts_prod,
                    prosumer_id: @prosumer_reverse_hash[item['prosumer_id'].to_s][:id],
                    interval_id: @interval.id,
                    forecast_time: nil,
                    forecast_type: 0
                }

                setter = {
                    production: item['f_production'],
                    storage: item['f_storage'],
                    created_at: DateTime.now,
                    updated_at: DateTime.now
                }

                setter.reject!{|k,v| v.nil?}

                upsert.row(selector, setter)
              end

            end
          end
          x.publish({data:  "Interval #{@interval.name}: UPSERT status: #{upsert_status.count}, prosumers: #{received_prosumers.keys}, time: #{min_ts} .. #{max_ts}", event: "output"}.to_json) if x
          Rails.logger.debug "Interval #{@interval.name}: UPSERT status: #{upsert_status.count}, prosumers: #{received_prosumers.keys}, time: #{min_ts} .. #{max_ts}"
        rescue PG::InvalidTextRepresentation => e
          x.publish({data:  "Interval #{@interval.name}: BAD DATA FORMAT: #{upsert_status}", event: "output"}.to_json)
          # x.publish({data:  "BAD DATA FORMAT: #{data}", event: "output"}.to_json)
          Rails.logger.debug "Interval #{@interval.name}: BAD DATA FORMAT: #{upsert_status}"
          # Rails.logger.debug "BAD DATA FORMAT: #{data}"
          raise e
        end

        begin
          data = {}

          received_prosumers.map{|k,v| Prosumer.find(k)}.each do |pr|

            pr.reload
            # pr.forecasts.reload
            data.merge!(pr.new_forecast(@interval, @startdate, @enddate))
          end
          # Rails.logger.debug "Sending FMS data: #{data}"
          x.publish(
              {
                  data: data,
                  event: 'fms_data'
              }.to_json
          ) unless x.nil?
        rescue Bunny::Exception # Don't block if channel can't be fanned out
          Rails.logger.debug "Can't publish to channel #{channel}"
        ensure
        end

      end
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
        when 60
          timestamp.to_datetime.to_i % 60 == 0
        when 300
          timestamp.to_datetime.to_i % 300 == 0
        when 900
          timestamp.to_datetime.to_i % 900 == 0
        when 3600
          timestamp.to_datetime.to_i % 3600 == 0
        when 86400
          # (DateTime.parse(timestamp).beginning_of_day + Time.zone.parse(timestamp).utc_offset.seconds) == (DateTime.parse(timestamp))
          true
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
              res /= 100.0 if result["ProsumerId"] == "HP_0061"
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


    def convert_new_to_old_api_v2(data, prosumer, forc)

      intermediate_data = {}
      result = data.first

      result["ProsumerId"] = prosumer if result["ProsumerId"].nil? || result["ProsumerId"] == ""

      # Rails.logger.debug result

      %w[Production Storage Consumption Flexibility Reliability].each do |key|
        parse_vals result, intermediate_data, key
      end unless forc # Dont add datapoints when forecasts are asked

      result["ForecastConsumption"].map(&method(:hash_to_key_value)).each do | key,value |

        key=key
        # puts "@@@@@@@@@@@@@@@@@@@ #{key.to_s}"
        if @interval.duration == 86400 && !is_valid_iso8601(key)
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = key.to_datetime.change(:offset => "+0200").to_s
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = (DateTime.parse(key).beginning_of_day + Time.zone.parse(key).utc_offset.seconds).to_s
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
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
        # puts "@@@@@@@@@@@@@@@@@@@ #{key.to_s}"
        if @interval.duration == 86400 && !is_valid_iso8601(key)
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = key.to_datetime.change(:offset => "+0200").to_s
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
          key = (DateTime.parse(key).beginning_of_day + Time.zone.parse(key).utc_offset.seconds).to_s
          # puts "@@@@@@@@@@@@@@@@@@@ #{key}"
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

      # Rails.logger.debug JSON.pretty_generate intermediate_data
      intermediate_data.values
    end

    def datareceived(data, x)

      # Rails.logger.debug "Finding existing datapoints"
      new_data_points = []
      ActiveRecord::Base.connection_pool.with_connection do | conn |
        begin
          upsert_status = Upsert.batch(conn, DataPoint.table_name) do |upsert|
            data.each do | d |

              if @prosumer_reverse_hash[d['procumer_id'].to_s]
                # puts "Received: #{d}"
                selector = {
                    timestamp: d['timestamp'].to_datetime,
                    prosumer_id: @prosumer_reverse_hash[d['procumer_id'].to_s][:id],
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
          prepare(d)
        end.compact
        x.publish({data: message, event: 'datapoints'}.to_json) unless x.nil?
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't publish to channel #{channel}"
      ensure
      end
    end

    def prepare(d)

      if @prosumer_reverse_hash[d['procumer_id'].to_s]
        k = d.deep_dup

        k['timestamp'] = d['timestamp'].to_datetime.to_i
        k['prosumer_id'] = @prosumer_reverse_hash[d['procumer_id'].to_s][:id]
        k['prosumer_name'] = @prosumer_reverse_hash[d['procumer_id'].to_s][:name]
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


    def dont_divide(edms_id)
      ["b827eb4c14af", "b827eb19fcf5", "b827ebc26e98", "b827ebe977a8"].include?(edms_id) ? 0 : 1
    end

  end
end

