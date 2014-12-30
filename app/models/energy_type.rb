# The different types of Energy sources, Solar, Wind, etc...
class EnergyType < ActiveRecord::Base
  has_many :energy_type_prosumers
end
