class EnergyTypeProsumer < ActiveRecord::Base
  belongs_to :energy_type
  belongs_to :prosumer
  
  validates_presence_of :power
end
