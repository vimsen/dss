require 'securerandom'

# The conroller for the prosumer model
class ProsumersController < ApplicationController
  before_action :set_prosumer, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  # GET /prosumers
  # GET /prosumers.json
  def index
    @prosumers = Prosumer.includes(:cluster, :building_type, :connection_type).category(params[:category]).
        order(sort_column + ' ' + sort_direction).paginate(page: params[:page], per_page: (params[:per_page] || 50))
  end

  # GET /prosumers/1
  # GET /prosumers/1.json
  def show
    @channel = "channel.#{SecureRandom.uuid}"
  end

  # GET /prosumers/new
  def new
    @prosumer = Prosumer.new(prosumer_category_id: params[:category])
  end

  # GET /prosumers/1/edit
  def edit
  end

  # POST /prosumers
  # POST /prosumers.json
  def create
    @prosumer = Prosumer.new(prosumer_params)
    @users = User.where(id: params[:users])
    @prosumer.users << @users

    respond_to do |format|
      if @prosumer.save
        format.html do
          redirect_to @prosumer, notice: 'Prosumer was successfully created.'
        end
        format.json { render :show, status: :created, location: @prosumer }
      else
        format.html { render :new }
        format.json do
          render json: @prosumer.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /prosumers/1
  # PATCH/PUT /prosumers/1.json
  def update
    @users = User.where(id: params[:users])
    @prosumer.users.destroy_all
    @prosumer.users << @users

    respond_to do |format|
      if @prosumer.update(prosumer_params)
        format.html do
          redirect_to @prosumer, notice: 'Prosumer was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @prosumer }
      else
        format.html { render :edit }
        format.json do
          render json: @prosumer.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /prosumers/1
  # DELETE /prosumers/1.json
  def destroy
    @prosumer.destroy
    respond_to do |format|
      format.html do
        redirect_to prosumers_url,
                    notice: 'Prosumer was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  def removefromcluster
    @prosumer = Prosumer.find_by(id: params[:id])
    @cluster = @prosumer.cluster

    respond_to do |format|
      if @prosumer.update(cluster_id: nil)
        format.html do
          redirect_to @cluster, notice: 'Prosumer was successfully removed.'
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
  def set_prosumer
    @prosumer = Prosumer.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list
  # through.
  def prosumer_params
    params.require(:prosumer).permit(:name, :prosumer_category_id,
                                     :feeder_id, :location, :cluster_id,
                                     :building_type_id, :connection_type_id,
                                     :edms_id, :location_x,
                                     :location_y,
                                     energy_type_prosumers_attributes: [
                                       :id, :power, :energy_type_id, :_destroy
                                     ])
  end

  def sort_column
    if (Prosumer.column_names + ['clusters.name', 'building_types.name', 'connection_types.name']
    ).include?(params[:sort])
      params[:sort]
    else
      'name'
    end
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ?  params[:direction] : 'asc'
  end
end
