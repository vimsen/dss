class DayAheadsController < ApplicationController
  before_action :set_day_ahead, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html

  def index
    @day_aheads = DayAhead.all
    respond_with(@day_aheads)
  end

  def show
    respond_with(@day_ahead)
  end

  def new
    @day_ahead = DayAhead.new
    respond_with(@day_ahead)
  end

  def edit
  end

  def create
    @day_ahead = DayAhead.new(day_ahead_params)
    @day_ahead.save
    respond_with(@day_ahead)
  end

  def update
    @day_ahead.update(day_ahead_params)
    respond_with(@day_ahead)
  end

  def destroy
    @day_ahead.destroy
    respond_with(@day_ahead)
  end

  private
    def set_day_ahead
      @day_ahead = DayAhead.find(params[:id])
    end

    def day_ahead_params
      params.require(:day_ahead).permit(:prosumer_id, :date)
    end
end
