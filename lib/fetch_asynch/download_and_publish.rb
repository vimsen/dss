require 'uri'
require 'open-uri'
require 'json'

module FetchAsynch
  class DownloadAndPublish
    def initialize prosumers, interval, startdate, enddate, channel
      Thread.new do
        ActiveRecord::Base.connection.close
        sleep 5;
        
        puts "fetching data: #{prosumers}, #{interval}, #{startdate}, #{enddate}"
       
        uri = URI.parse('http://localhost:3000/intellen_mock/getdata');
        params = {:prosumers => prosumers,
                  :startdate => startdate.to_i,
                  :enddate => enddate.to_i,
                  :interval => Interval.find(interval).duration}
        ActiveRecord::Base.connection.close
        uri.query = URI.encode_www_form(params);
        
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
            x.publish(d.to_json)
          else
            puts "Datapoint found"
          end
          ActiveRecord::Base.connection.close
        end
        ActiveRecord::Base.connection.close
      end
         
      def newdata? d 
        puts "===== In newData ======"
        t = d["timestamp"].to_i
        i = d["interval"].to_i
        s = Time.at(t - i/2).to_datetime
        e = Time.at(t + i/2).to_datetime
        
        puts d
        
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
        h = {timestamp: Time.at(d["timestamp"]).to_datetime, 
              prosumer: Prosumer.find(d["prosumer_id"].to_i),
              interval: Interval.where(duration: d["interval"].to_i).first,
              production: d["actual"]["production"],
              consumption: d["actual"]["consumption"],
              storage: d["actual"]["storage"],
              f_timestamp: Time.at(d["forecast"]["timestamp"]).to_datetime,
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
    end
end
