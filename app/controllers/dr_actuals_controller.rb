class DrActualsController < ApplicationController
  before_action :set_dr_actual, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource

  # GET /dr_actuals
  # GET /dr_actuals.json
  def index
    @dr_actuals = DrActual.all
  end

  # GET /dr_actuals/1
  # GET /dr_actuals/1.json
  def show
  end

  # GET /dr_actuals/new
  def new
    @dr_actual = DrActual.new
  end

  # GET /dr_actuals/1/edit
  def edit
  end

  # POST /dr_actuals
  # POST /dr_actuals.json
  def create
    @dr_actual = DrActual.new(dr_actual_params)

    respond_to do |format|
      if @dr_actual.save
        format.html { redirect_to @dr_actual, notice: 'Dr actual was successfully created.' }
        format.json { render :show, status: :created, location: @dr_actual }
      else
        format.html { render :new }
        format.json { render json: @dr_actual.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dr_actuals/1
  # PATCH/PUT /dr_actuals/1.json
  def update
    respond_to do |format|
      if @dr_actual.update(dr_actual_params)
        format.html { redirect_to @dr_actual, notice: 'Dr actual was successfully updated.' }
        format.json { render :show, status: :ok, location: @dr_actual }
      else
        format.html { render :edit }
        format.json { render json: @dr_actual.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dr_actuals/1
  # DELETE /dr_actuals/1.json
  def destroy
    @dr_actual.destroy
    respond_to do |format|
      format.html { redirect_to dr_actuals_url, notice: 'Dr actual was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dr_actual
      @dr_actual = DrActual.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dr_actual_params
      params.require(:dr_actual).permit(:prosumer_id, :volume, :timestamp, :demand_response_id)
    end
end
