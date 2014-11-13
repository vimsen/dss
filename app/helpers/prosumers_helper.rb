module ProsumersHelper
  def setup_prosumer(prosumer)
    (EnergyType.all - prosumer.energy_types).each do |et|
      prosumer.energy_type_prosumers.build(:energy_type => et)
    end
    prosumer
  end
end
