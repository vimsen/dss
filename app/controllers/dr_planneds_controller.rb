class DrPlannedsController < ApplicationController
  before_action :set_dr_planned, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource

  # GET /dr_planneds
  # GET /dr_planneds.json
  def index
    @dr_planneds = DrPlanned.all
  end

  # GET /dr_planneds/1
  # GET /dr_planneds/1.json
  def show
  end

  # GET /dr_planneds/new
  def new
    @dr_planned = DrPlanned.new
  end

  # GET /dr_planneds/1/edit
  def edit
  end

  # POST /dr_planneds
  # POST /dr_planneds.json
  def create
    @dr_planned = DrPlanned.new(dr_planned_params)

    respond_to do |format|
      if @dr_planned.save
        format.html { redirect_to @dr_planned, notice: 'Dr planned was successfully created.' }
        format.json { render :show, status: :created, location: @dr_planned }
      else
        format.html { render :new }
        format.json { render json: @dr_planned.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dr_planneds/1
  # PATCH/PUT /dr_planneds/1.json
  def update
    respond_to do |format|
      if @dr_planned.update(dr_planned_params)
        format.html { redirect_to @dr_planned, notice: 'Dr planned was successfully updated.' }
        format.json { render :show, status: :ok, location: @dr_planned }
      else
        format.html { render :edit }
        format.json { render json: @dr_planned.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dr_planneds/1
  # DELETE /dr_planneds/1.json
  def destroy
    @dr_planned.destroy
    respond_to do |format|
      format.html { redirect_to dr_planneds_url, notice: 'Dr planned was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dr_planned
      @dr_planned = DrPlanned.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dr_planned_params
      params.require(:dr_planned).permit(:prosumer_id, :volume, :timestamp, :demand_response_id)
    end
end
