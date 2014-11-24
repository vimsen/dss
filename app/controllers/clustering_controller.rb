class ClusteringController < ApplicationController
  def select
  end

  def confirm
    @clusters = run_algorithm params[:algorithm]
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
          :name => 'By connection type'}]
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
    
    def run_algorithm algo
      case algo
      when "energy_type"
        return run_energy_type
      when "building_type"
        return run_building_type
      when "connection_type"
        return run_connection_type
      else
        return nil
      end
    end
  
end
