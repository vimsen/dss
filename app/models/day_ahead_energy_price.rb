class DayAheadEnergyPrice < ActiveRecord::Base
  belongs_to :region,  class_name: "EnergyRegion"
end
