require 'clustering/genetic_error_clustering2'
require 'clustering/spectral_clustering'


# This module implements the clustering algorithms for the demo
module ClusteringModule

  def self.algorithms
    {
        energy_type: {
            string: 'By renewable type',
            proc: ->(k) { run_energy_type k }
        },
        building_type: {
            string: 'By building type',
            proc: ->(k) { run_building_type k }
        },
        connection_type: {
            string: 'By connection type',
            proc: ->(k) { run_connection_type k }
        },
        location: {
            string: 'By location',
            proc: ->(k) { run_location k }
        },
        dr: {
            string: 'By demand response profile',
            proc: ->(k) { run_dr k }
        },
        genetic: {
            string: 'Using genetic algorithms',
            proc: ->(params) {
              ClusteringModule::GeneticErrorClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"],
                  forecast_type: (params["category"].first.to_i == 4 ? :fms : :edms)
              ).run params["kappa"].to_i
            }
        },
        genetic_smart: {
            string: 'Genetic algorithm with smart reproduction',
            proc: ->(params) {
              ClusteringModule::GeneticErrorClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"],
                  algorithm: Ai4r::GeneticAlgorithm::StaticChromosomeWithSmartCrossover,
                  forecast: params["category"].first.to_i == 4 ? :fms : :edms
              ).run params["kappa"].to_i
            }
        },
        positive_error_spectral_clustering: {
            string: 'Positive Error Spectral Clustering',
            proc: ->(params) {
              ClusteringModule::PositiveErrorSpectralClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"],
                  forecast: params["category"].first.to_i == 4 ? :fms : :edms
              ).run params["kappa"].to_i
            }
        },
        negative_error_spectral_clustering: {
            string: 'Negative Error Spectral Clustering',
            proc: ->(params) {
              ClusteringModule::NegativeErrorSpectralClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"],
                  forecast: params["category"].first.to_i == 4 ? :fms : :edms
              ).run params["kappa"].to_i
            }
        },
        positive_consumption_spectral_clustering: {
            string: 'Positive Consumption Spectral Clustering',
            proc: ->(params) {
              ClusteringModule::PositiveConsumptionSpectralClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"]
              ).run params["kappa"].to_i
            }
        },
        negative_consumption_spectral_clustering: {
            string: 'Negative Consumption Spectral Clustering',
            proc: ->(params) {
              ClusteringModule::NegativeConsumptionSpectralClustering.new(
                  prosumers: ProsumerCategory.find(params["category"].first.to_i).prosumers,
                  startDate: params["startDate"],
                  endDate: params["endDate"]
              ).run params["kappa"].to_i
            }
        }
    }
  end

  def self.run_algorithm(params)
    result = self.algorithms.with_indifferent_access[params["algorithm"]][:proc].call(params)

    result.select { |cl| cl.prosumers.size > 0 }
  end

  private

  def self.run_energy_type(params)
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

    Prosumer.category(ProsumerCategory.find params["category"]).each do |p|
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

  def self.run_connection_type(params)
    cat = ProsumerCategory.find params["category"]
    result = []
    cl = TempCluster.new name: 'No con. info.',
                     description: 'No connection info.'
    cl.prosumers << Prosumer.where(connection_type: nil, prosumer_category: params["category"])
    result.push(cl)

    ConnectionType.all.each do |bt|
      cl = TempCluster.new name: "CL: #{bt.name}",
                       description: "Prosumers with #{bt.name} connection."

      cl.prosumers << Prosumer.where(connection_type: bt, prosumer_category: params["category"])
      result.push(cl)
    end
    result
  end

  def self.run_building_type(params)
    result = []
    cl = TempCluster.new name: 'No buil. info',
                     description: 'No building type info.'

    cl.prosumers << Prosumer.where(building_type: nil, prosumer_category: params["category"])
    result.push(cl)

    BuildingType.all.each do |bt|
      cl = TempCluster.new name: "CL: #{bt.name}",
                       description: "Prosumers with #{bt.name} building type."
      cl.prosumers << Prosumer.where(building_type: bt, prosumer_category: params["category"])

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

  def self.run_location(params)
    cat = ProsumerCategory.find(params["category"].first.to_i)
    # puts "Category is: #{params["category"]}, ------- #{cat}"
    result = Prosumer.with_locations.category(cat).sample(params["kappa"].to_i).map.with_index do |p, i|
      cl = TempCluster.new name: "Loc: #{i}",
                       description: "Location based cluster #{i}."
      cl.prosumers.push p
      cl
    end

    centroids = result.map { |cl| get_centroid(cl) }
    loop do
      old_centroids = Array.new(centroids)
      result.each { |cl| cl.prosumers.clear }
      Prosumer.with_locations.category(cat).each do |p|
        find_closest(p, centroids).prosumers.push p
      end
      centroids = result.map { |cl| get_centroid(cl) }
      break if centroids <=> old_centroids
    end

    without_location = Prosumer.category(cat) - Prosumer.with_locations.category(cat)

    if without_location.count > 0
      cl = TempCluster.new name: 'No loc.',
                       description: 'Prosumers with no Location info available.'
      cl.prosumers << without_location
      result.push cl
    end
    result
  end

  def self.run_dr(params)
    cat = ProsumerCategory.find(params["category"].first.to_i)
    range = params["startDate"] .. params["endDate"]
    result = Prosumer.category(cat).with_positive_dr(range).sample(params["kappa"].to_i).map.with_index do |p, i|
       [ p.id ]
    end

    dr_vector = Prosumer.category(cat).avg_dr_all(range)

    dr_prosumers = Prosumer.category(cat).with_dr(range)

    centroids = result.map { |cl| get_centroid_dr(cl, dr_vector) }
    loop do
      old_centroids = Array.new centroids
      # Rails.logger.debug "Old centroids: #{old_centroids}"
      result.each { |cl| cl.clear }
      dr_prosumers.each do |p|
        cl = find_closest_dr(dr_vector[p.id], centroids)
        cl.push p.id
      end
      result = result.select { |cl| cl.size > 0}
      centroids = result.map { |cl| get_centroid_dr cl, dr_vector }
      break if centroids <=> old_centroids
    end

    without_dr = Prosumer.category(cat) - dr_prosumers

    if without_dr.count > 0
      cl = []
      cl << without_dr.map{|p| p.id}
      result.push cl
    end

    result.map.with_index do |c, i|
      # Rails.logger.debug "Prosumer ids are: #{c}"
      cl = TempCluster.new name: "Dr: #{i}",
                           description: "Demand Response based cluster #{i}"
      cl.prosumers = Prosumer.where(id: c)
      cl
    end
  end
end
