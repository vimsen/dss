require 'uri'
require 'open-uri'

class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  has_many :data_points, dependent: :destroy

  belongs_to :cluster
  resourcify

  has_and_belongs_to_many :users
  
  def request_cached(interval, startdate, enddate)
    result = []
    puts "#{interval}, #{startdate}, #{enddate}"
    self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc).each do |dp|
      result.push({
        :timestamp => dp.timestamp.to_i,
        :prosumer_id => self.id,
        :interval => interval,
        :actual => {
          :production => dp.production,
          :consumption => dp.consumption,
          :storage => dp.storage
        },
        :forecast => {
          :timestamp => dp.f_timestamp.to_i,
          :production => dp.f_production,
          :consumption => dp.f_consumption,
          :storage => dp.f_storage
        }, 
        :dr => dp.dr,
        :reliability => dp.reliability
      })  
    end
     
    fetch_from_intelen(interval, startdate, enddate)
    return result      
  end
  
  def fetch_from_intelen(interval, startdate, enddate)
    Thread.new do
      ActiveRecord::Base.connection.close
      sleep 5;
      
      puts "fetching data, #{interval}, #{startdate}, #{enddate}"
     
      uri = URI.parse('http://localhost:3000/intellen_mock/getdata');
      params = {:prosumer => self.id,
                :startdate => startdate.to_i,
                :enddate => enddate.to_i,
                :interval => Interval.find(interval).duration}
      ActiveRecord::Base.connection.close                
      uri.query = URI.encode_www_form(params);
      
      result = JSON.parse(uri.open.read)
      datareceived(result)
      
      
      
      puts "done"
    end
  end
  
  def datareceived(data)
    
   # puts "data: #{data}"

#    measurement = Measurement.new(timeslot: DateTime.now, power: power, prosumer_id: params[:id] )
#    measurement.save

    x = $bunny_channel.fanout("prosumer.#{self.id}")
    
    puts "Received something"
    data.each do |d|
      puts "Message! #{d}"
      t = d["timestamp"].to_i
      i = d["interval"].to_i
      intervalid = Interval.where(duration: i).first
      s = Time.at(t - i).to_datetime
      e = Time.at(t + i).to_datetime
      datapoint = DataPoint.where(timestamp: s..e, interval_id: intervalid, prosumer: self).first

      
      if (datapoint.nil?)
        puts "No datapoint"
        
        h = {timestamp: Time.at(t).to_datetime, 
              prosumer: self,
              interval: intervalid,
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
        x.publish(d.to_json)
        puts "Published DataPoint"
      else 
        puts "Datapoint found"
      end
     #  puts "published message", d
    end
    ActiveRecord::Base.connection.close

  end
  
end
