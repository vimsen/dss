class EnergyType < ActiveRecord::Base
  has_many :energy_type_prosumers

end
