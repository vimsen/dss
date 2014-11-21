class ProsumersController < ApplicationController
  before_action :set_prosumer, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /prosumers
  # GET /prosumers.json
  def index
    @prosumers = Prosumer.all
  end

  # GET /prosumers/1
  # GET /prosumers/1.json
  def show
  end

  # GET /prosumers/new
  def new
    @prosumer = Prosumer.new
  end

  # GET /prosumers/1/edit
  def edit
  end

  # POST /prosumers
  # POST /prosumers.json
  def create
    @prosumer = Prosumer.new(prosumer_params)
    @users = User.where(:id => params[:users])
    @prosumer.users << @users
    
    respond_to do |format|
      if @prosumer.save
        format.html { redirect_to @prosumer, notice: 'Prosumer was successfully created.' }
        format.json { render :show, status: :created, location: @prosumer }
      else
        format.html { render :new }
        format.json { render json: @prosumer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prosumers/1
  # PATCH/PUT /prosumers/1.json
  def update

    @users = User.where(:id => params[:users])
    @prosumer.users.destroy_all
    @prosumer.users << @users    
    
    respond_to do |format|
      if @prosumer.update(prosumer_params)
        format.html { redirect_to @prosumer, notice: 'Prosumer was successfully updated.' }
        format.json { render :show, status: :ok, location: @prosumer }
      else
        format.html { render :edit }
        format.json { render json: @prosumer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prosumers/1
  # DELETE /prosumers/1.json
  def destroy
    @prosumer.destroy
    respond_to do |format|
      format.html { redirect_to prosumers_url, notice: 'Prosumer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def removefromcluster
    @prosumer = Prosumer.find_by(id: params[:id])
    @cluster = @prosumer.cluster
    
    respond_to do |format|
      if @prosumer.update(cluster_id: nil)
        format.html { redirect_to @cluster, notice: 'Prosumer was successfully removed.' }
        format.json { render :show, status: :ok, location: @cluster }
      else
        format.html { render :edit }
        format.json { render json: @cluster.errors, status: :unprocessable_entity }
      end
    end
  end
   
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prosumer
      @prosumer = Prosumer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def prosumer_params
      params.require(:prosumer).permit(:name, :location, :cluster_id, :building_type_id, :connection_type_id, :intelen_id,
        :energy_type_prosumers_attributes => [:id, :power, :energy_type_id, :_destroy])
    end
end
