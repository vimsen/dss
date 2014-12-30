require 'uri'
require 'open-uri'
require 'json'
require 'yaml'

module FetchAsynch
  class DownloadAndPublish
    def initialize prosumers, interval, startdate, enddate, channel
      Thread.new do
        ActiveRecord::Base.connection.close
        sleep 1; 
        
        u = YAML.load_file('config/config.yml')[Rails.env]["intellen_host"]
        puts "fetching data: #{prosumers}, #{interval}, #{startdate}, #{enddate}, #{u}"
       
        uri = URI.parse(u+"/getdata");
        params = {:prosumers => prosumers,
                  :startdate => startdate.to_s,
                  :enddate => enddate.to_s,
                  :interval => Interval.find(interval).duration}
        ActiveRecord::Base.connection.close
        uri.query = URI.encode_www_form(params);
        
        puts "Connecting to: #{uri}"
        
        ActiveRecord::Base.connection.close
        result = JSON.parse(uri.open.read)
        datareceived(result, channel)
  
        puts "done"
      end
    end
    
    private
   
      def datareceived(data, channel)
        begin
          x = $bunny_channel.fanout(channel)
        rescue Bunny::Exception # Don't block if channel can't be fanned out
          puts "Can't fanout channel #{channel}"
          x = nil
        end
        data.each do |d|
          if newdata? d
            dbinsert d
            puts "Publishing to channel: #{channel}"
            x.publish(prepare d) unless x.nil?
          else
            puts "Datapoint found"
          end
          ActiveRecord::Base.connection.close
        end
        ActiveRecord::Base.connection.close
      end
         
      def newdata? d 
        puts "===== In newData ======"
        t = DateTime.parse(d["timestamp"])
        
        # Intelen sends us data for the future for some reaason
        if t.future?
          return false
        end 
        
        i = d["interval"].to_i
        s = Time.at(t.to_i - i/2).to_datetime
        e = Time.at(t.to_i + i/2).to_datetime
        
        # procumer should be changed to prosumer (by intelen)
        p = Prosumer.where(intelen_id: d["procumer_id"].to_i).first
        
        datapoint = DataPoint.where(
                           timestamp: s..e, 
                           interval_id: Interval.where(duration: i).first, 
                           prosumer: p
                           ).first
        puts "===== Result : #{d["procumer_id"]}, #{p}, #{datapoint.nil?} =========="
        return datapoint.nil? 
    
      end
      
      def dbinsert d
        puts "New datapoint"
        puts Interval.where(duration: d["interval"].to_i).first
        puts "===="
        h = {timestamp: DateTime.parse(d["timestamp"]), 
              prosumer: Prosumer.where(intelen_id: d["procumer_id"].to_i).first,
              interval: Interval.where(duration: d["interval"].to_i).first,
              production: d["actual"]["production"],
              consumption: d["actual"]["consumption"],
              storage: d["actual"]["storage"],
              f_timestamp: DateTime.parse(d["forecast"]["timestamp"]),
              f_production: d["forecast"]["production"],
              f_consumption: d["forecast"]["consumption"],
              f_storage: d["forecast"]["storage"],
              dr: d["dr"],
              reliability: d["reliability"]
              }
        
        puts "h=", h
        datapoint = DataPoint.new(h)
        puts "Crated DataPoint: #{datapoint}"
        datapoint.save
        puts "Saved DataPoint"
      end
      
      def prepare d
        puts "------------------- #{d["timestamp"]} #{DateTime.parse(d["timestamp"]).to_i}"
        d["timestamp"] = DateTime.parse(d["timestamp"]).to_i;
        d[:prosumer_id] = Prosumer.where(intelen_id: d["procumer_id"]).first.id
        d[:prosumer_name] = Prosumer.where(intelen_id: d["procumer_id"]).first.name
        d["forecast"]["timestamp"] = DateTime.parse(d["forecast"]["timestamp"]).to_i;
        d.to_json
      end
  end
end
