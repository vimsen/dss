class EnergyType < ActiveRecord::Base
  has_many :energy_type_prosumers

  validates_presence_of :power
end
