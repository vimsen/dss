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
    def initialize(prosumers, interval, startdate, enddate, channel)
      @prosumers = prosumers.to_s
      @startdate = startdate
      @enddate = enddate
      @interval = Interval.find(interval)
      ActiveRecord::Base.clear_active_connections!
      Thread.new do
        ActiveRecord::Base.clear_active_connections!

     #   sleep 1

        u = YAML.load_file('config/config.yml')[Rails.env]['intellen_host']
        uri = URI.parse(u + '/getdata')
        params = { prosumers: prosumers,
                   startdate: startdate.to_s,
                   enddate: enddate.to_s,
                   interval: @interval.duration }
        ActiveRecord::Base.clear_active_connections!
        uri.query = URI.encode_www_form(params)

        Rails.logger.debug "Connecting to: #{uri}"

        ActiveRecord::Base.clear_active_connections!
        result = JSON.parse(uri.open.read)
        datareceived(result, channel)
        ActiveRecord::Base.clear_active_connections!
        Rails.logger.debug 'done'
      end
    end

    private

    def datareceived(data, channel)

      ActiveRecord::Base.clear_active_connections!
      Rails.logger.debug "Connecting to channel"
      begin
        bunny_channel = $bunny.create_channel
        x = bunny_channel.fanout(channel)
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't fanout channel #{channel}"
        x = nil
      end

      Rails.logger.debug "Finding existing datapoints"
      ActiveRecord::Base.clear_active_connections!

      procs = Hash[Prosumer.all.map {|p| [p.intelen_id, p]}]
      new_data_points = []
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("LOCK TABLE data_points IN EXCLUSIVE MODE;")
        old_data_points = Hash[DataPoint
                                   .where(prosumer: @prosumers.split(/,/),
                                          timestamp: (@startdate - 2.days) ..
                                              (@enddate + 2.days),
                                          interval: @interval)
                                   .map do |dp|
                                 ["#{dp.timestamp.to_i},#{dp.prosumer_id},#{dp.interval_id}", 1]
                               end]
        Rails.logger.debug "#{old_data_points.count} datapoints found"
        Rails.logger.debug "#{data.count} datapoints received"

        dupe_finder = {}

        new_data_points = data.reject do |r|
          f = false
          unless dupe_finder["#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}"].nil?
            f = true
          end
          dupe_finder["#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}"] = 1
          r['timestamp'].to_datetime.future? ||
              old_data_points.has_key?("#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}") ||
              f
        end

        Rails.logger.debug "#{new_data_points.count} datapoints remaining"
        (new_data_points.map do |d|
          db_prepare(d, procs)
        end).each_slice(5000) do |slice|
          DataPoint.import slice
        end
        ActiveRecord::Base.clear_active_connections!
      end

      begin
        message = new_data_points.map do |d|
          ActiveRecord::Base.clear_active_connections!
          prepare(d, procs)
        end
        ActiveRecord::Base.clear_active_connections!
        x.publish({data: message, event: 'datapoints'}.to_json) unless x.nil?
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't publish to channel #{channel}"
      ensure
        ActiveRecord::Base.clear_active_connections!
      end

      Rails.logger.debug "publshing market data"
      begin
        ActiveRecord::Base.clear_active_connections!
        x.publish({data: Market::Calculator.new(prosumers: @prosumers.split(/,/),
                                                startDate: @startdate,
                                                endDate: @enddate).calcCosts,
                event: 'market'}.to_json) # unless x.nil?
        Rails.logger.debug "publshed market data"
        ActiveRecord::Base.clear_active_connections!
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't publish to channel #{channel}"
        ActiveRecord::Base.clear_active_connections!
      end
      ActiveRecord::Base.clear_active_connections!
      Rails.logger.debug "market data published."

    end

    def db_prepare(d, procs)
     DataPoint.new(
         timestamp: d['timestamp'].to_datetime,
         prosumer: procs[d['procumer_id']],
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
      k['prosumer_id'] = procs[d['procumer_id']].id
      k['prosumer_name'] = procs[d['procumer_id']].name
      k['forecast']['timestamp'] =
          d['forecast']['timestamp'].to_datetime.to_i
      return k
    end
  end
end
