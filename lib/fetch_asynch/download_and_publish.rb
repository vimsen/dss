require 'uri'
require 'open-uri'
require 'json'
require 'yaml'

module FetchAsynch
  class DownloadAndPublish
    def initialize prosumers, interval, startdate, enddate, channel
      Thread.new do
        ActiveRecord::Base.connection.close
        sleep 5;
        
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
        
        result = JSON.parse(uri.open.read)
        datareceived(result, channel)
  
        puts "done"
      end
    end
    
    private
   
      def datareceived(data, channel)
        x = $bunny_channel.fanout(channel)
        data.each do |d|
          if newdata? d
            dbinsert d
            x.publish(prepare d)
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
        i = d["interval"].to_i
        s = Time.at(t.to_i - i/2).to_datetime
        e = Time.at(t.to_i + i/2).to_datetime
        
        datapoint = DataPoint.where(
                           timestamp: s..e, 
                           interval_id: Interval.where(duration: i).first, 
                           prosumer: Prosumer.find(d["prosumer_id"].to_i)
                           ).first
        puts "===== Result : #{datapoint.nil?} =========="
        return datapoint.nil? 
    
      end
      
      def dbinsert d
        puts "New datapoint"
        puts Interval.where(duration: d["interval"].to_i).first
        puts "===="
        h = {timestamp: DateTime.parse(d["timestamp"]), 
              prosumer: Prosumer.find(d["prosumer_id"].to_i),
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
        d["timestamp"] = DateTime.parse(d["timestamp"]).to_i;
        d[:prosumer_name] = Prosumer.find(d["prosumer_id"]).name;
        d["forecast"]["timestamp"] = DateTime.parse(d["forecast"]["timestamp"]).to_i;
        d.to_json
      end
  end
end
