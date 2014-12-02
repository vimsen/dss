module ProsumersHelper
  def setup_prosumer(prosumer)
    (EnergyType.all - prosumer.energy_types).each do |et|
      prosumer.energy_type_prosumers.build(:energy_type => et)
    end
    prosumer
  end
  
  def color(cluster)
    if cluster.nil?
      return '000000'
    end
    numcolors = Cluster.count
    last = 0xFFFFFF
    sprintf("%06X", last * (numcolors - cluster.get_icon_index) / (numcolors))
  end
  
  def prosumers_with_locations
    Prosumer.where("location_x IS NOT NULL and location_y IS NOT NULL") 
  end
end
