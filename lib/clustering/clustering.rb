# This module implements the clustering algorithms for the demo
module Clustering
  def self.algorithms
    [{ string: :energy_type,
       name: 'By renewable type' },
     { string: :building_type,
       name: 'By building type' },
     { string: :connection_type,
       name: 'By connection type' },
     { string: :location,
       name: 'By location' }]
  end

  def self.run_algorithm(algo, param)
    case algo
    when 'energy_type'
      result = run_energy_type
    when 'building_type'
      result = run_building_type
    when 'connection_type'
      result = run_connection_type
    when 'location'
      result = run_location param.to_i
    else
      return nil
    end

    result.select { |cl| cl.prosumers.size > 0 }
  end

  private

  def self.run_energy_type
    result = {}
    cl = Cluster.new name: 'No ren.',
                     description: 'No info about renewable energy.'
    result[:none] = cl
    EnergyType.all.each do |et|
      cl = Cluster.new name: "CL: #{et.name}",
                       description: "Prosumers with primarily #{et.name} "\
                                    'energy production'
      result[et.id] = cl
    end

    Prosumer.all.each do |p|
      etp = p.energy_type_prosumers.order('power DESC').first
      if etp.nil?
        result[:none].prosumers.push(p)
      else
        etid = etp.energy_type.id
        result[etid].prosumers.push(p)
      end
    end

    result.values
  end

  def self.run_connection_type
    result = []
    cl = Cluster.new name: 'No con. info.',
                     description: 'No connection info.'
    cl.prosumers << Prosumer.where(connection_type: nil)
    result.push(cl)

    ConnectionType.all.each do |bt|
      cl = Cluster.new name: "CL: #{bt.name}",
                       description: "Prosumers with #{bt.name} connection."

      cl.prosumers << Prosumer.where(connection_type: bt)
      result.push(cl)
    end
    result
  end

  def self.run_building_type
    result = []
    cl = Cluster.new name: 'No buil. info',
                     description: 'No building type info.'

    cl.prosumers << Prosumer.where(building_type: nil)
    result.push(cl)

    BuildingType.all.each do |bt|
      cl = Cluster.new name: "CL: #{bt.name}",
                       description: "Prosumers with #{bt.name} building type."
      cl.prosumers << Prosumer.where(building_type: bt)

      result.push(cl)
    end
    result
  end

  def self.get_centroid(cluster)
    sum_x = 0
    sum_y = 0
    count = 0
    cluster.prosumers.each do |p|
      fail 'Found prosumer without location' if p.location_x.nil? ||
                                                p.location_y.nil?
      sum_x += p.location_x
      sum_y += p.location_y
      count += 1
    end
    {
      x: sum_x / count,
      y: sum_y / count,
      cluster: cluster
    }
  end

  def self.distance(prosumer, centroid)
    (prosumer.location_x - centroid[:x])**2 +
      (prosumer.location_y - centroid[:y])**2
  end

  def self.find_closest(prosumer, centroids)
    min = Float::MAX
    closest = nil
    centroids.each do |centroid|
      d = distance(prosumer, centroid)
      if d < min
        min = d
        closest = centroid[:cluster]
      end
    end
    closest
  end

  def self.run_location(kappa)
    result = Prosumer.with_locations.sample(kappa).map.with_index do |p, i|
      cl = Cluster.new name: "Loc: #{i}",
                       description: "Location based cluster #{i}."
      cl.prosumers.push p
      cl
    end

    centroids = result.map { |cl| get_centroid(cl) }
    loop do
      old_centroids = Array.new(centroids)
      result.each { |cl| cl.prosumers.clear }
      Prosumer.with_locations.each do |p|
        find_closest(p, centroids).prosumers.push p
      end
      centroids = result.map { |cl| get_centroid(cl) }
      break if centroids <=> old_centroids
    end

    without_location = Prosumer.all - Prosumer.with_locations

    if without_location.count > 0
      cl = Cluster.new name: 'No loc.',
                       description: 'Prosumers with no Location info available.'
      cl.prosumers << without_location
      result.push cl
    end
    result
  end
end
