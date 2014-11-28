module ProsumersHelper
  def setup_prosumer(prosumer)
    (EnergyType.all - prosumer.energy_types).each do |et|
      prosumer.energy_type_prosumers.build(:energy_type => et)
    end
    prosumer
  end
  
  def color(i)
    numcolors = Cluster.count
    last = 0xFFFFFF
    sprintf("%06X", last * (numcolors - i) / (numcolors))
  end
end
