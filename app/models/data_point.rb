class DataPoint < ActiveRecord::Base
  belongs_to :prosumer
  belongs_to :interval
  
  def clientFormat
    return {
        :timestamp => self.timestamp.to_i,
        :prosumer_id => self.prosumer_id,
        :interval => self.interval.duration,
        :actual => {
          :production => self.production,
          :consumption => self.consumption,
          :storage => self.storage
        },
        :forecast => {
          :timestamp => self.f_timestamp.to_i,
          :production => self.f_production,
          :consumption => self.f_consumption,
          :storage => self.f_storage
        }, 
        :dr => self.dr,
        :reliability => self.reliability
      }
  end
 
end
