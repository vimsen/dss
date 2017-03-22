class DemandResponsesController < ApplicationController
  before_action :set_demand_response, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource

  # GET /demand_responses
  # GET /demand_responses.json
  def index
    @demand_responses = DemandResponse.order(id: :desc).paginate(page: params[:page])
  end

  # GET /demand_responses/1
  # GET /demand_responses/1.json
  def show
    @idata = @demand_response.dr_properties
  rescue RestClient::Exception, Errno::ECONNREFUSED => e
    @idata = @demand_response.dr_properties
    flash.now[:alert] = "Failed to connect to GDRMS"

    Rails.logger.debug e.message
    Rails.logger.debug e.response if e.respond_to? :response
  end

  # GET /demand_responses/new
  def new
    @demand_response = DemandResponse.new
  end

  # GET /demand_responses/1/edit
  def edit
  end

  # POST /demand_responses
  # POST /demand_responses.json
  def create
    @demand_response = DemandResponse.new(demand_response_params)

    respond_to do |format|
      if @demand_response.save
        format.html { redirect_to @demand_response, notice: 'Demand response was successfully created.' }
        format.json { render :show, status: :created, location: @demand_response }
      else
        format.html { render :new }
        format.json { render json: @demand_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /demand_responses/1
  # PATCH/PUT /demand_responses/1.json
  def update
    respond_to do |format|
      if @demand_response.update(demand_response_params)
        format.html { redirect_to @demand_response, notice: 'Demand response was successfully updated.' }
        format.json { render :show, status: :ok, location: @demand_response }
      else
        format.html { render :edit }
        format.json { render json: @demand_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /demand_responses/1
  # DELETE /demand_responses/1.json
  def destroy
    @demand_response.destroy
    respond_to do |format|
      format.html { redirect_to demand_responses_url, notice: 'Demand response was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_demand_response
      @demand_response = DemandResponse.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def demand_response_params
      params.require(:demand_response).permit(:interval_id, :issuer, :feeder_id, :prosumer_category_id, :event_type, dr_targets_attributes: [:id, :volume, :timestamp])
    end
end
