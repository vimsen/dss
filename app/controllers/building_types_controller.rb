class BuildingTypesController < ApplicationController
  before_action :set_building_type, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  def index
    @building_types = BuildingType.all
    respond_with(@building_types)
  end

  def show
    respond_with(@building_type)
  end

  def new
    @building_type = BuildingType.new
    respond_with(@building_type)
  end

  def edit
  end

  def create
    @building_type = BuildingType.new(building_type_params)
    @building_type.save
    respond_with(@building_type)
  end

  def update
    @building_type.update(building_type_params)
    respond_with(@building_type)
  end

  def destroy
    @building_type.destroy
    respond_with(@building_type)
  end

  private
    def set_building_type
      @building_type = BuildingType.find(params[:id])
    end

    def building_type_params
      params.require(:building_type).permit(:name)
    end
end
