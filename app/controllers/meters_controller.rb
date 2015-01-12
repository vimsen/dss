class MetersController < ApplicationController
  before_action :set_meter, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html
  load_and_authorize_resource

  def index
    @meters = Meter.all
    respond_with(@meters)
  end

  def show
    respond_with(@meter)
  end

  def new
    @meter = Meter.new
    respond_with(@meter)
  end

  def edit
  end

  def create
    @meter = Meter.new(meter_params)
    flash[:notice] = 'Meter was successfully created.' if @meter.save
    respond_with(@meter)
  end

  def update
    flash[:notice] = 'Meter was successfully updated.' if @meter.update(meter_params)
    respond_with(@meter)
  end

  def destroy
    @meter.destroy
    respond_with(@meter)
  end

  private
    def set_meter
      @meter = Meter.find(params[:id])
    end

    def meter_params
      params.require(:meter).permit(:mac, :prosumer_id)
    end
end
