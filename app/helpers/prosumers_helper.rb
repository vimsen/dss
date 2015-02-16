module ProsumersHelper
  def setup_prosumer(prosumer)
    (EnergyType.all - prosumer.energy_types).each do |et|
      prosumer.energy_type_prosumers.build(:energy_type => et)
    end
    prosumer
  end
  
  def color_map(size = 10)
    result = []
        # use golden ratio
    golden_ratio_conjugate = 0.618033988749895
    h = golden_ratio_conjugate # use the above as start value

    1.upto size do |i|
      result[i - 1] = hsv_to_rgb(h, 0.5, 0.95)
      h += golden_ratio_conjugate
      h %= 1
    end
    result
  end
  
  def color(prosumer, clustering = nil)
    if clustering.nil?
      if prosumer.cluster.nil?
        return '000000'
      end
      numcolors = Cluster.count
      ind = prosumer.cluster.get_icon_index
    else
      ind = clustering.get_icon_index (prosumer)
      if ind == 'N'
        return '000000'
      else
        numcolors = clustering.temp_clusters.count
      end
    end
    sprintf "%06X", tostring((color_map numcolors)[ind ])

  end
  
  def tostring colorArray
    ((colorArray[0] * 256) + colorArray[1]) * 256 + colorArray[2]
  end
  
  # HSV values in [0..1[
  # returns [r, g, b] values from 0 to 255
  def hsv_to_rgb(h, s, v)
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    [(r*256).to_i, (g*256).to_i, (b*256).to_i]
  end
  
  def letter(prosumer, clustering = nil)
    if clustering.nil?
      if prosumer.cluster.nil?
        return 'N'
      end
      prosumer.cluster.get_icon_index
    else
      clustering.get_icon_index(prosumer)
    end
  end
  
  def prosumers_with_locations
    Prosumer.where("location_x IS NOT NULL and location_y IS NOT NULL") 
  end
end
