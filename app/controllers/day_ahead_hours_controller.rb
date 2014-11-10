class DayAheadHoursController < ApplicationController
  before_action :set_day_ahead_hour, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html

  def index
    @day_ahead_hours = DayAheadHour.all
    respond_with(@day_ahead_hours)
  end

  def show
    respond_with(@day_ahead_hour)
  end

  def new
    @day_ahead_hour = DayAheadHour.new
    respond_with(@day_ahead_hour)
  end

  def edit
  end

  def create
    @day_ahead_hour = DayAheadHour.new(day_ahead_hour_params)
    @day_ahead_hour.save
    respond_with(@day_ahead_hour)
  end

  def update
    @day_ahead_hour.update(day_ahead_hour_params)
    respond_with(@day_ahead_hour)
  end

  def destroy
    @day_ahead_hour.destroy
    respond_with(@day_ahead_hour)
  end

  private
    def set_day_ahead_hour
      @day_ahead_hour = DayAheadHour.find(params[:id])
    end

    def day_ahead_hour_params
      params.require(:day_ahead_hour).permit(:day_ahead_id, :time, :production, :consumption)
    end
end
