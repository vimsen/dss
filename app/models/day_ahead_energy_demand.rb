class DayAheadEnergyDemand < ActiveRecord::Base
  belongs_to :region,  class_name: "EnergyRegion"
end
