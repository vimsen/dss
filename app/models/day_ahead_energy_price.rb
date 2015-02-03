class DayAheadEnergyPrice < ActiveRecord::Base
  belongs_to :market,  class_name: "EnergyMarket"
end
