class EnergyTypesController < ApplicationController
  before_action :set_energy_type, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html
  load_and_authorize_resource
  
  def index
    @energy_types = EnergyType.all
    respond_with(@energy_types)
  end

  def show
    respond_with(@energy_type)
  end

  def new
    @energy_type = EnergyType.new
    respond_with(@energy_type)
  end

  def edit
  end

  def create
    @energy_type = EnergyType.new(energy_type_params)
    @energy_type.save
    respond_with(@energy_type)
  end

  def update
    @energy_type.update(energy_type_params)
    respond_with(@energy_type)
  end

  def destroy
    @energy_type.destroy
    respond_with(@energy_type)
  end

  private
    def set_energy_type
      @energy_type = EnergyType.find(params[:id])
    end

    def energy_type_params
      params.require(:energy_type).permit(:name)
    end
end
