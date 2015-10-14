require 'clustering/genetic_error_clustering2'
require 'clustering/spectral_clustering'


# This module implements the clustering algorithms for the demo
module ClusteringModule
  def self.algorithms
    [{ string: :energy_type,
       name: 'By renewable type' },
     { string: :building_type,
       name: 'By building type' },
     { string: :connection_type,
       name: 'By connection type' },
     { string: :location,
       name: 'By location' },
     { string: :dr,
       name: "By demand response profile"},
     # { string: :error,
     #  name: "By forecasting errors"},
     { string: :genetic,
       name: "Using genetic algorithms"},
     { string: :positive_error_spectral_clustering,
       name: "Positive Error Spectral Clustering"},
     { string: :negative_error_spectral_clustering,
       name: "Negative Error Spectral Clustering"},
     { string: :positive_consumption_spectral_clustering,
       name: "Positive Consumption Spectral Clustering"},
     { string: :negative_consumption_spectral_clustering,
       name: "Negative Consumption Spectral Clustering"}]

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
      when 'dr'
        result = run_dr param.to_i
      when 'error'
        result = ForecastErrorClustering.new.run param.to_i
      when 'genetic'
        result = ClusteringModule::GeneticErrorClustering.new.run param.to_i
      when 'positive_error_spectral_clustering'
        result = ClusteringModule::PositiveErrorSpectralClustering.new.run param.to_i
      when 'negative_error_spectral_clustering'
        result = ClusteringModule::NegativeErrorSpectralClustering.new.run param.to_i
      when 'positive_consumption_spectral_clustering'
        result = ClusteringModule::PositiveConsumptionSpectralClustering.new.run param.to_i
      when 'negative_consumption_spectral_clustering'
        result = ClusteringModule::NegativeConsumptionSpectralClustering.new.run param.to_i
      else
        return nil
    end

    result.select { |cl| cl.prosumers.size > 0 }
  end

  private

  def self.run_energy_type
    result = {}
    cl = TempCluster.new name: 'No ren.',
                     description: 'No info about renewable energy.'
    result[:none] = cl
    EnergyType.all.each do |et|
      cl = TempCluster.new name: "CL: #{et.name}",
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
    cl = TempCluster.new name: 'No con. info.',
                     description: 'No connection info.'
    cl.prosumers << Prosumer.where(connection_type: nil)
    result.push(cl)

    ConnectionType.all.each do |bt|
      cl = TempCluster.new name: "CL: #{bt.name}",
                       description: "Prosumers with #{bt.name} connection."

      cl.prosumers << Prosumer.where(connection_type: bt)
      result.push(cl)
    end
    result
  end

  def self.run_building_type
    result = []
    cl = TempCluster.new name: 'No buil. info',
                     description: 'No building type info.'

    cl.prosumers << Prosumer.where(building_type: nil)
    result.push(cl)

    BuildingType.all.each do |bt|
      cl = TempCluster.new name: "CL: #{bt.name}",
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

  def self.get_centroid_dr(cluster, dr_vector)
    {
        dr: cluster.map {|p| dr_vector[p]}.sum / cluster.size,
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

  def self.find_closest_dr(dr, centroids)
    (centroids.min_by do |c|
      (c[:dr] - dr).abs
    end)[:cluster]
  end

  def self.run_location(kappa)
    result = Prosumer.with_locations.sample(kappa).map.with_index do |p, i|
      cl = TempCluster.new name: "Loc: #{i}",
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
      cl = TempCluster.new name: 'No loc.',
                       description: 'Prosumers with no Location info available.'
      cl.prosumers << without_location
      result.push cl
    end
    result
  end

  def self.run_dr(kappa)
    result = Prosumer.with_positive_dr.sample(kappa).map.with_index do |p, i|
       [ p.id ]
    end

    dr_vector = Hash[Prosumer.all.map {|p| [p.id, p.max_dr]}]

    dr_prosumers = Prosumer.with_dr

    centroids = result.map { |cl| get_centroid_dr(cl, dr_vector) }
    loop do
      old_centroids = Array.new centroids
      puts "Old centroids: ", old_centroids
      result.each { |cl| cl.clear }
      dr_prosumers.each do |p|
        cl = find_closest_dr(dr_vector[p.id], centroids)
        cl.push p.id
      end
      result = result.select { |cl| cl.size > 0}
      centroids = result.map { |cl| get_centroid_dr cl, dr_vector }
      break if centroids <=> old_centroids
    end

    without_dr = Prosumer.all - dr_prosumers

    if without_dr.count > 0
      cl = []
      cl << without_dr.map{|p| p.id}
      result.push cl
    end
    result.map.with_index do |c, i|
      puts "Prosumer ids are: #{c}"
      cl = TempCluster.new name: "Dr: #{i}",
                           description: "Demand Response based cluster #{i}"
      c.each do |p|
        cl.prosumers << Prosumer.find(p)
      end
      cl
    end
  end
end
