class EnergyPricesController < ApplicationController
  before_action :set_energy_price, only: [:show, :edit, :update, :destroy]

  def index
    @energy_prices = EnergyPrice.all
    respond_with(@energy_prices)
  end

  def show
    respond_with(@energy_price)
  end

  def new
    @energy_price = EnergyPrice.new
    respond_with(@energy_price)
  end

  def edit
  end

  def create
    @energy_price = EnergyPrice.new(energy_price_params)
    @energy_price.save
    respond_with(@energy_price)
  end

  def update
    @energy_price.update(energy_price_params)
    respond_with(@energy_price)
  end

  def destroy
    @energy_price.destroy
    respond_with(@energy_price)
  end

  private
    def set_energy_price
      @energy_price = EnergyPrice.find(params[:id])
    end

    def energy_price_params
      params.require(:energy_price).permit(:date, :dayhour, :price)
    end
end
