class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  has_many :data_points, dependent: :destroy

  belongs_to :cluster
  resourcify

  has_and_belongs_to_many :users
  
  def request_cached(interval, startdate, enddate)
    result = []
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
    return result      
  end
end
