require 'clustering/clustering_module'

# This is the controller handles the automatic clustring BL
class ClusteringController < ApplicationController
  respond_to :json, :html
  authorize_resource class: false

  def index
    @clusterings = Clustering.all
  end

  def show
    @clustering = Clustering.find(params[:id])
  end

  def new
    @clustering = Clustering.new
    respond_with(@clustering)
  end

  def edit
    @clusters = params[:id].nil? ? Cluster.all : Clustering.find(params[:id]).temp_clusters
  end

  def create
    @clustering = Clustering.new(clustering_params)
    flash[:notice] = 'Clustering was successfully create.' if @clustering.save
    respond_with(@clustering)
  end

  def update
    @clustering = Clustering.find(params[:id])
    flash[:notice] = 'Clustering was successfully updated' if @clustering.save
    respond_with(@clustering)
  end

  def destroy
    @clustering = Clustering.find(params[:id])
    @clustering.destroy
    respond_with(@clustering)
  end

  def select
  end

  def confirm
    @clusters = ClusteringModule.run_algorithm params[:algorithm], params[:kappa]
  end

  def save
    ActiveRecord::Base.transaction do
      params[:clusterprosumers].zip(
            params[:clusternames], params[:clusterdescriptions],
            params[:clusterids]).each do |prosumers, clustername, desc, clid|
        prs = Prosumer.find(prosumers.split(','))
        if clid.to_i == -1
          prs.each do |p|
            p.cluster = nil
            p.save
          end
        else
          cluster = clid.to_i > 0 ? Cluster.find(clid) : Cluster.new
          cluster.name = clustername
          cluster.description = desc

          cluster.prosumers << prs
          cluster.save!
        end
      end

      Cluster.all.each do |cl|
        cl.destroy if cl.prosumers.size == 0
      end

      respond_to do |format|
        format.html do
          redirect_to clusters_path,
                      notice: 'Clusters were successfully updated.'
        end
      end
    end
  rescue
    respond_to do |format|
      format.html do
        redirect_to '/clustering/select',
                    alert: 'Clusters were NOT successfully updated.'
      end
    end
  end

  helper_method :algorithms

  private

  def algorithms
    ClusteringModule.algorithms
  end
end
