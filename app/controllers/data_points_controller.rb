# The controller for the DataPoint model
class DataPointsController < ApplicationController
  before_action :set_data_point, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    # @data_points = DataPoint.all
    @data_points = DataPoint.joins(:prosumer, :interval).order(
      sort_column + ' ' + sort_direction).paginate(page: params[:page])
    respond_with(@data_points)
  end

  def show
    respond_with(@data_point)
  end

  def new
    @data_point = DataPoint.new
    respond_with(@data_point)
  end

  def edit
  end

  def create
    @data_point = DataPoint.new(data_point_params)
    @data_point.save
    respond_with(@data_point)
  end

  def update
    @data_point.update(data_point_params)
    respond_with(@data_point)
  end

  def destroy
    @data_point.destroy
    respond_with(@data_point)
  end

  private

  def set_data_point
    @data_point = DataPoint.find(params[:id])
  end

  def data_point_params
    params.require(:data_point).permit(
      :prosumer_id, :interval_id, :timestamp, :production, :consumption,
      :storage, :f_timestamp, :f_production, :f_consumption, :f_storage,
      :dr, :reliability)
  end

  def sort_column
    if (DataPoint.column_names + ['prosumers.name', 'intervals.duration']
      ).include?(params[:sort])
      params[:sort]
    else
      'timestamp'
    end
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ?  params[:direction] : 'desc'
  end
end
