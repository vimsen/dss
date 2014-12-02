class ClusteringController < ApplicationController
  
  authorize_resource :class => false

  
  def select
  end

  def confirm
    @clusters = run_algorithm params[:algorithm], params[:kappa]
    puts @clusters
  end

  def save
    begin
      ActiveRecord::Base.transaction do
        params[:clusterprosumers].zip(params[:clusternames]).each do |prosumers, clustername|
          cluster = Cluster.new(name: clustername)
          prs = Prosumer.find( prosumers.split(",") )
          cluster.prosumers << prs
          cluster.save!
        end
        
        Cluster.all.each do |cl|
          if cl.prosumers.size == 0
            cl.destroy
          end
        end
        
        respond_to do |format|
          format.html { redirect_to clusters_path, notice: 'Clusters were successfully updated.' }
        end
      end
    rescue 
      respond_to do |format|
        format.html { redirect_to "/clustering/select", alert: 'Clusters were NOT successfully updated.' }
      end
    end
  end


  helper_method :algorithms 
  
  private
    def algorithms
      [
        {:string => :energy_type,
          :name => 'By renewable type'}, 
        {:string => :building_type,
          :name => 'By building type'},
        {:string => :connection_type,
          :name => 'By connection type'},
        {:string => :location,
          :name => 'By location'}]
    end
    
    def run_energy_type
      result = {}
      cl = Cluster.new(name: "No renewable info")
      result[:none] = cl
      EnergyType.all.each do |et|
        cl = Cluster.new(name: et.name)
        result[et.id] = cl
      end
      
      Prosumer.all.each do |p|
        etp = p.energy_type_prosumers.order("power DESC").first
        if etp.nil?
          result[:none].prosumers.push(p)
        else
          etid = etp.energy_type.id
          result[etid].prosumers.push(p)   
        end
      end
      
      return result.values
    end
    
    def run_connection_type
      result = []
      cl = Cluster.new(name: "No connection type") 
      cl.prosumers << Prosumer.where(connection_type: nil)
      result.push(cl) 
            
      ConnectionType.all.each do |bt|
        cl = Cluster.new(name: "with #{bt.name}")
        cl.prosumers << Prosumer.where(connection_type: bt)
        result.push(cl)
      end      
      return result
    end
    
    def run_building_type
      result = []
      cl = Cluster.new(name: "No buiding type") 
      cl.prosumers << Prosumer.where(building_type: nil)
      result.push(cl) 
            
      BuildingType.all.each do |bt|
        cl = Cluster.new(name: "with #{bt.name}")
        cl.prosumers << Prosumer.where(building_type: bt)
 
        result.push(cl)
      end      
      return result
    end
    
    def get_centroid(cluster)
      sum_x = 0
      sum_y = 0
      count = 0
      cluster.prosumers.each do |p|
        raise "Found prosumer without location" if p.location_x.nil? || p.location_y.nil? 
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
    
    def distance(prosumer, centroid)
      (prosumer.location_x - centroid[:x]) ** 2 + (prosumer.location_y - centroid[:y]) ** 2
    end
    
    
    def findClosest(prosumer, centroids)
      min = Float::MAX
      closest = nil
      centroids.each_with_index do |centroid, i|
        d = distance(prosumer, centroid)
        if d < min
          min = d
          closest = centroid[:cluster]
        end
      end
      closest
    end
    
    def run_location(kappa)
      
      result = Prosumer.with_locations.sample(kappa).map.with_index do |p, i|
        cl = Cluster.new(name: "Location based cluster #{i}")
        cl.prosumers.push p
        cl
      end

      centroids = result.map { |cl| get_centroid(cl) }
      begin
        old_centroids = Array.new(centroids)
        
        result.each { |cl| cl.prosumers.clear }
        Prosumer.with_locations.each do |p|
          findClosest(p, centroids).prosumers.push p
        end
         
        centroids = result.map { |cl| get_centroid(cl) }
        puts "centroids: #{centroids}"
      end until centroids <=> old_centroids

      without_location = Prosumer.all - Prosumer.with_locations
      
      if without_location.count > 0
        cl = Cluster.new(name: "No location info")
        cl.prosumers << without_location
        result.push cl
      end      
      
      return result
      
    end
    
    def run_algorithm(algo, param)
      case algo
      when "energy_type"
        return run_energy_type
      when "building_type"
        return run_building_type
      when "connection_type"
        return run_connection_type
      when "location"
        return run_location param.to_i
      else
        return nil
      end
    end
  
end
