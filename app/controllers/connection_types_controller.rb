# The controller for the connection types model.
class ConnectionTypesController < ApplicationController
  before_action :set_connection_type, only: [:show, :edit, :update, :destroy]
  respond_to :json, :html
  load_and_authorize_resource

  def index
    @connection_types = ConnectionType.all
    respond_with(@connection_types)
  end

  def show
    respond_with(@connection_type)
  end

  def new
    @connection_type = ConnectionType.new
    respond_with(@connection_type)
  end

  def edit
  end

  def create
    @connection_type = ConnectionType.new(connection_type_params)
    @connection_type.save
    respond_with(@connection_type)
  end

  def update
    @connection_type.update(connection_type_params)
    respond_with(@connection_type)
  end

  def destroy
    @connection_type.destroy
    respond_with(@connection_type)
  end

  private

  def set_connection_type
    @connection_type = ConnectionType.find(params[:id])
  end

  def connection_type_params
    params.require(:connection_type).permit(:name)
  end
end
