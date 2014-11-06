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
      sleep 10;
      puts "fetching data, #{interval}, #{startdate}, #{enddate}"
     
      uri = URI.parse('http://localhost:3000/intellen_mock/getdata');
      params = {:prosumer => self.id,
                :startdate => startdate.to_i,
                :enddate => enddate.to_i,
                :interval => Interval.find(interval).duration}
      uri.query = URI.encode_www_form(params);
      
      result = JSON.parse(uri.open.read)
      datareceived(result)
      
      ActiveRecord::Base.connection.close
      puts "done"
    end
  end
  
  def datareceived(data)
    
   # puts "data: #{data}"

#    measurement = Measurement.new(timeslot: DateTime.now, power: power, prosumer_id: params[:id] )
#    measurement.save

    x = $bunny_channel.fanout("prosumer.#{self.id}")
    

    data.each do |d|
      x.publish(d.to_json)
     #  puts "published message", d
    end

  end
  
end
