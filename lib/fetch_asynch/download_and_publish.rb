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
    def initialize(prosumers, interval, startdate, enddate, channel, async = false, overwrite_data = false)
      @prosumers = prosumers
      @startdate = startdate
      @enddate = enddate
      @overwrite_data = overwrite_data
      ActiveRecord::Base.connection_pool.with_connection do
        @interval = Interval.find(interval)
      end

      puts "Starting new Thread..."
      thread = Thread.new do
        ActiveRecord::Base.forbid_implicit_checkout_for_thread!
        #   sleep 1
        i = 0
        u = YAML.load_file('config/config.yml')[Rails.env]['intellen_host']

        puts i; i=i+1;
        uri = URI.parse(u + '/getdata')
        puts i; i=i+1;
        params = {}
        ActiveRecord::Base.connection_pool.with_connection do
          params = { prosumers: prosumers.map {|p| p.intelen_id}.join(","),
                     startdate: startdate.to_s,
                     enddate: enddate.to_s,
                     interval: @interval.duration }
        end
        puts i; i=i+1;
        uri.query = URI.encode_www_form(params)
        puts i; i=i+1;

        puts "In the new Thread..."
        Rails.logger.debug "Connecting to: #{uri}"
        result = JSON.parse(uri.open.read)
        datareceived(result, channel)
        Rails.logger.debug 'done'
      end
      thread.join if (async)
    end

    private

    def datareceived(data, channel)

      Rails.logger.debug "Connecting to channel"
      begin
        bunny_channel = $bunny.create_channel if channel
        x = bunny_channel.fanout(channel) if channel
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't fanout channel #{channel}"
        x = nil
      end

      Rails.logger.debug "Finding existing datapoints"
      new_data_points = []
      procs = []

      Upsert.logger = Logger.new("/dev/null")

      ActiveRecord::Base.connection_pool.with_connection do | conn |
        procs = Hash[@prosumers.map {|p| [p.intelen_id, p]}]

        Upsert.batch(conn, DataPoint.table_name) do |upsert|
          data.each do | d |
            upsert.row({
                           timestamp: d['timestamp'].to_datetime,
                           prosumer_id: procs[d['procumer_id']].id,
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
            ) unless d['timestamp'].to_datetime.future?
          end
        end

        new_data_points = data.reject do |d|
          d['timestamp'].to_datetime.future?
        end


=begin
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("LOCK TABLE data_points IN EXCLUSIVE MODE;")
          old_data_points = Hash[DataPoint
                                     .where(prosumer: @prosumers,
                                            timestamp: (@startdate - 2.days) ..
                                                (@enddate + 2.days),
                                            interval: @interval)
                                     .map do |dp|
                                   ["#{dp.timestamp.to_i},#{dp.prosumer_id},#{dp.interval_id}", 1]
                                 end]
          Rails.logger.debug "#{old_data_points.count} datapoints found"
          x.publish({data:  "Interval #{@interval.name}: #{old_data_points.count} datapoints found.", event: "output"}.to_json) if x
          Rails.logger.debug "#{data.count} datapoints received"
          x.publish({data:  "Interval #{@interval.name}: #{data.count} datapoints received.", event: "output"}.to_json) if x

          dupe_finder = {}


          new_data_points = @overwrite_data ? data : data.reject do |r|
            is_duplicate = dupe_finder.has_key?("#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}")
            dupe_finder["#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}"] = 1
            r['timestamp'].to_datetime.future? ||
                old_data_points.has_key?("#{r['timestamp'].to_datetime.to_i},#{procs[r['procumer_id']].id},#{@interval.id}") ||
                is_duplicate
          end

          Rails.logger.debug "#{new_data_points.count} datapoints remaining"
          x.publish({data:  "Interval #{@interval.name}: #{new_data_points.count} datapoints remaining.", event: "output"}.to_json) if x

          (new_data_points.map do |d|
            db_prepare(d, procs)
          end).each_slice(5000) do |slice|
            DataPoint.import(slice)
            x.publish({data:  "Interval #{@interval.name}: Inserted datapoints.", event: "output"}.to_json) if x
          end
        end
=end
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

      Rails.logger.debug "publshing market data"
      begin

        Rails.logger.debug "Trying to publish market data"
        x.publish({data: Market::Calculator.new(prosumers: @prosumers,
                                                startDate: @startdate,
                                                endDate: @enddate).calcCosts,
                event: 'market'}.to_json) if x
        Rails.logger.debug "publshed market data"
        ActiveRecord::Base.connection_pool.with_connection do
          x.publish({data:  "Interval #{@interval.name}: complete.", event: "output"}.to_json) if x
        end
        Rails.logger.debug "pushed end message"
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        Rails.logger.debug "Can't publish to channel #{channel}"
      end
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
