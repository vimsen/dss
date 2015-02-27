require 'uri'
require 'open-uri'
require 'json'
require 'yaml'
require 'market/market'

module FetchAsynch
  # This class downloads prosumption data from the EDMS, and then inserts them
  # in the DB, and publishes the results to the appropriate rabbitMQ channel.
  class DownloadAndPublish
    def initialize(prosumers, interval, startdate, enddate, channel)
      @prosumers = prosumers.to_s
      @startdate = startdate
      @enddate = enddate
      @interval = Interval.find(interval)
      Thread.new do
        ActiveRecord::Base.connection.close

     #   sleep 1

        u = YAML.load_file('config/config.yml')[Rails.env]['intellen_host']
        uri = URI.parse(u + '/getdata')
        params = { prosumers: prosumers,
                   startdate: startdate.to_s,
                   enddate: enddate.to_s,
                   interval: @interval.duration }
        ActiveRecord::Base.connection.close
        uri.query = URI.encode_www_form(params)

        puts "Connecting to: #{uri}"

        ActiveRecord::Base.connection.close
        result = JSON.parse(uri.open.read)
        datareceived(result, channel)

        puts 'done'
      end
    end

    private

    def datareceived(data, channel)

      ActiveRecord::Base.connection.close
      puts "Connecting to channel"
      begin
        x = $bunny_channel.fanout(channel)
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        puts "Can't fanout channel #{channel}"
        x = nil
      end

      puts "Finding existing datapoints"
      ActiveRecord::Base.connection.close
      old_data_points = DataPoint.where(prosumer: @prosumers.split(/,/),
                                    timestamp: (@startdate - 1.day)..(@enddate + 1.day),
                                    interval: @interval)
      puts "#{old_data_points.count} datapoints found"
      procs = Hash[Prosumer.all.map {|p| [p.intelen_id, p]}]
      ActiveRecord::Base.connection.close

      puts "Rejecting existing data"

      new_data_points = data.reject do |r|
        r['timestamp'].to_datetime.future? ||
          old_data_points.any? do |d|
            d.timestamp == r['timestamp'].to_datetime &&
                d.prosumer_id == procs[r['procumer_id']].id &&
                d.interval_id == @interval.id
          end
      end
      ActiveRecord::Base.connection.close
      puts "#{new_data_points.count} remaining. Publishing to rabbitmq #{channel}"

      begin
        message = new_data_points.map do |d|
          ActiveRecord::Base.connection.close
          prepare(d, procs)
        end
        ActiveRecord::Base.connection.close
        x.publish({data: message, event: 'datapoints'}.to_json) unless x.nil?
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        puts "Can't publish to channel #{channel}"
        ActiveRecord::Base.connection.close
      end
      ActiveRecord::Base.connection.close

      puts "Preparing data for db"

      prepared = new_data_points.map do |d|
        db_prepare(d, procs)
        ActiveRecord::Base.connection.close
      end
      ActiveRecord::Base.connection.close
      puts "Inserting to db"

      DataPoint.import prepared

      puts "Inserted to db"
      ActiveRecord::Base.connection.close

      puts "publshing market data"
      begin
        puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@", @prosumers.split(/,/), @startdate, @enddate
        x.publish({data: Market::Calculator.new(prosumers: @prosumers.split(/,/),
                                              startDate: @startdate,
                                              endDate: @enddate).calcCosts,
                event: 'market'}.to_json) # unless x.nil?
        puts "publshed market data"
        ActiveRecord::Base.connection.close
      rescue Bunny::Exception # Don't block if channel can't be fanned out
        puts "Can't publish to channel #{channel}"
        ActiveRecord::Base.connection.close
      end
      ActiveRecord::Base.connection.close

    end

    def newdata?(d)
      puts '===== In newData ======'
      t = DateTime.parse(d['timestamp'])

      # Intelen sends us data for the future for some reaason
      return false if t.future?

      i = d['interval'].to_i
      s = Time.at(t.to_i - i / 2).to_datetime
      e = Time.at(t.to_i + i / 2).to_datetime

      # procumer should be changed to prosumer (by intelen)
      p = Prosumer.where(intelen_id: d['procumer_id'].to_i).first

      datapoint = DataPoint.where(
                         timestamp: s..e,
                         interval_id: Interval.where(duration: i).first,
                         prosumer: p
                         ).first
      puts "=== Result : #{d['procumer_id']}, #{p}, #{datapoint.nil?} ======="
      datapoint.nil?
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

    def dbinsert(d)
      puts 'New datapoint'
      puts Interval.where(duration: d['interval'].to_i).first
      puts '===='
      h = { timestamp: DateTime.parse(d['timestamp']),
            prosumer: Prosumer.where(intelen_id: d['procumer_id'].to_i).first,
            interval: Interval.where(duration: d['interval'].to_i).first,
            production: d['actual']['production'],
            consumption: d['actual']['consumption'],
            storage: d['actual']['storage'],
            f_timestamp: DateTime.parse(d['forecast']['timestamp']),
            f_production: d['forecast']['production'],
            f_consumption: d['forecast']['consumption'],
            f_storage: d['forecast']['storage'],
            dr: d['dr'],
            reliability: d['reliability'] }

      puts 'h=', h
      datapoint = DataPoint.new(h)
      puts "Crated DataPoint: #{datapoint}"
      datapoint.save
      puts 'Saved DataPoint'
    end

    def prepare(d, procs)
      k = d.deep_dup
      k['timestamp'] = d['timestamp'].to_datetime.to_i
      k[:prosumer_id] = procs[d['procumer_id']]
      k[:prosumer_name] = procs[d['procumer_id']].name
      k['forecast']['timestamp'] =
          d['forecast']['timestamp'].to_datetime.to_i
      return k
    end
  end
end
