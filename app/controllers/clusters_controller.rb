require 'securerandom'

# The controller for the clusters
class ClustersController < ApplicationController
  before_action :set_cluster, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /clusters
  # GET /clusters.json
  def index
    @clusters = Cluster.all
  end

  # GET /clusters/1
  # GET /clusters/1.json
  def show
    @channel = "channel.#{SecureRandom.uuid}"
  end

  # GET /clusters/new
  def new
    @cluster = Cluster.new
  end

  # GET /clusters/1/edit
  def edit
  end

  # POST /clusters
  # POST /clusters.json
  def create
    @cluster = Cluster.new(cluster_params)
    @prosumers = Prosumer.where(id: params[:prosumers])
    @cluster.prosumers << @prosumers

    respond_to do |format|
      if @cluster.save
        format.html do
          redirect_to @cluster,
                      notice: 'Cluster was successfully created.'
        end
        format.json { render :show, status: :created, location: @cluster }
      else
        format.html { render :new }
        format.json do
          render json: @cluster.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /clusters/1
  # PATCH/PUT /clusters/1.json
  def update
    @prosumers = Prosumer.where(id: params[:prosumers])
    @cluster.prosumers.each do |p|
      p.cluster = nil
      p.save
    end
    @cluster.prosumers << @prosumers

    respond_to do |format|
      if @cluster.update(cluster_params)
        format.html do
          redirect_to @cluster, notice: 'Cluster was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @cluster }
      else
        format.html { render :edit }
        format.json do
          render json: @cluster.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /clusters/1
  # DELETE /clusters/1.json
  def destroy
    @cluster.destroy
    respond_to do |format|
      format.html do
        redirect_to clusters_url, notice: 'Cluster was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  def addprosumer
    prosumer = Prosumer.find_by(id: params[:prosumer][:prosumer_id])
    @cluster = Cluster.find_by(id: params[:id])

    respond_to do |format|
      if prosumer.update(cluster_id: @cluster.id)
        format.html do
          redirect_to @cluster, notice: 'Prosumer was successfully added.'
        end
        format.json { render :show, status: :ok, location: @cluster }
      else
        format.html { render :edit }
        format.json do
          render json: @cluster.errors, status: :unprocessable_entity
        end
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_cluster
    @cluster = Cluster.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list
  # through.
  def cluster_params
    params.require(:cluster).permit(:name, :description)
  end
end
