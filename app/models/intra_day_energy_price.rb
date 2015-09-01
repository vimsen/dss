class IntraDayEnergyPrice < ActiveRecord::Base
  belongs_to :region,  class_name: "MarketRegions"
end
