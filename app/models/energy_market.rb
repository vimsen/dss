class EnergyMarket < ActiveRecord::Base

   has_many :day_ahead_energy_prices
   has_many :intra_day_energy_prices
end
