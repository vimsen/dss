require 'fetch_asynch/download_day_ahead'


class DayAheadsController < ApplicationController
  before_action :set_day_ahead, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html
  load_and_authorize_resource

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
    intelen_id = Prosumer.find(day_ahead_params[:prosumer_id].to_i).intelen_id
    puts "params: #{day_ahead_params}"
    date = "#{day_ahead_params["date(1i)"]}/#{day_ahead_params["date(2i)"]}/#{day_ahead_params["date(3i)"]}"
    
    FetchAsynch::DownloadDayAhead.new intelen_id, @day_ahead, date
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
