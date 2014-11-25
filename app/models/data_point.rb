class DataPoint < ActiveRecord::Base
  belongs_to :prosumer
  belongs_to :interval
  def clientFormat
    return {
      :timestamp => self.timestamp.to_i,
      :prosumer_id => self.prosumer_id,
      :prosumer_name => self.prosumer_id < 0 ? "" : self.prosumer.name,
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

  def add_data_doint dp
    self.production += dp.production
    self.consumption += dp.consumption
    self.storage += dp.storage
    self.f_production += dp.f_production
    self.f_consumption += dp.f_consumption
    self.f_storage += dp.f_storage
  end
  
  def init_zero timestamp, prosumer_id, interval, f_timestamp
    self.timestamp = timestamp
    self.prosumer_id = prosumer_id
    self.interval = interval
    self.f_timestamp = f_timestamp
    self.production = 0
    self.consumption = 0
    self.storage = 0
    self.f_production = 0
    self.f_consumption = 0
    self.f_storage = 0
  end
end
