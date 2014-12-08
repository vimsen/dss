require 'clustering/clustering'

class ClusteringController < ApplicationController
  
  authorize_resource :class => false

  def select
  end

  def confirm
    @clusters = Clustering.run_algorithm params[:algorithm], params[:kappa]
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
      Clustering.algorithms
    end
 
end
