require 'clustering/clustering_module'

# This is the controller handles the automatic clustring BL
class ClusteringsController < ApplicationController

  before_action :set_clustering, only: [:show, :edit, :update, :destroy]

  respond_to :json, :html
  authorize_resource class: false

  def index
    @clusterings = Clustering.all
  end

  def show
  end

  def new
    @clustering = Clustering.new
    @clustering.temp_clusters.build
    respond_with(@clustering)
  end

  def new_from_existing
    @clustering = Clustering.new(name: "From existing",
                                 description: "Clustering generated from existing clusters at #{Time.now}"   )
    Cluster.all.each do |c|
      @clustering.temp_clusters << TempCluster.new(name: c.name,
                                                   description: c.description,
                                                   prosumers: c.prosumers,
                                                   clustering: @clustering)
    end
    puts "CLUSTERING=====", @clustering
    respond_with(@clustering)
  end

  def edit

  end

  def create
    @clustering = Clustering.new(clustering_params)
    ActiveRecord::Base.transaction do
      if @clustering.save
        flash[:notice] = 'Clustering was successfully created.'
        unless params[:clusterprosumers].nil?
          @clustering.temp_clusters.zip(params[:clusterprosumers]).each do |tc, pros_list|
            tc.prosumers = Prosumer.find(pros_list.split(','))
          end
        end

      else
        flash[:error] = 'Clustering was NOT successfully created.'
      end
    end
    respond_with(@clustering)
  end

  def update
    ActiveRecord::Base.transaction do
    #  @temp_clusters = TempCluster.where(id: params[:temp_clusters])
      clusterids = params[:clustering][:temp_clusters_attributes];

      if clusterids.nil?
        @clustering.temp_clusters.destroy_all
      else
        @clustering.temp_clusters.where.not(id: clusterids.map {|k,v| v["id"]}).destroy_all
      end

      if @clustering.update(clustering_params)
        flash[:notice] = 'Clustering was successfully updated'

        unless params[:clusterprosumers].nil?
          @clustering.temp_clusters.zip(params[:clusterprosumers]).each do |tc, pros_list|
            tc.prosumers = Prosumer.find(pros_list.split(','))
          end
        end

      else
        flash[:error] = 'Clustering was NOT successfully updated'
      end
      respond_with(@clustering)
    end
  end

  def destroy
    @clustering.destroy
    respond_with(@clustering)
  end

  def select
  end

  def confirm
    @clustering = Clustering.new(name: "Auto #{params[:algorithm]}",
                                 description: "Automatic cluster generated with #{params[:algorithm]} algorithm.");
    @clustering.temp_clusters = ClusteringModule.run_algorithm params[:algorithm], params[:kappa]
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
        redirect_to '/clusterings/select',
                    alert: 'Clusters were NOT successfully updated.'
      end
    end
  end

  helper_method :algorithms

  private

  def algorithms
    ClusteringModule.algorithms
  end

  def set_clustering
    @clustering = Clustering.find(params[:id])
  end

  def clustering_params
    params.require(:clustering).permit(
        :name,
        :description,
        :temp_clusters_attributes => [
            :id,
            :name,
            :description,
            :_destroy
        ]
    )
  end
end
