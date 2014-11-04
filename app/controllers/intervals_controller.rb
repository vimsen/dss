class IntervalsController < ApplicationController
  before_action :set_interval, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html

  def index
    @intervals = Interval.all
    respond_with(@intervals)
  end

  def show
    respond_with(@interval)
  end

  def new
    @interval = Interval.new
    respond_with(@interval)
  end

  def edit
  end

  def create
    @interval = Interval.new(interval_params)
    @interval.save
    respond_with(@interval)
  end

  def update
    @interval.update(interval_params)
    respond_with(@interval)
  end

  def destroy
    @interval.destroy
    respond_with(@interval)
  end

  private
    def set_interval
      @interval = Interval.find(params[:id])
    end

    def interval_params
      params.require(:interval).permit(:duration, :name)
    end
end
