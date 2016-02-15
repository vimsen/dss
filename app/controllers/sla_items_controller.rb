class SlaItemsController < ApplicationController
  before_action :set_sla_item, only: [:show, :edit, :update, :destroy]

  # GET /sla_items
  # GET /sla_items.json
  def index
    @sla_items = SlaItem.all
  end

  # GET /sla_items/1
  # GET /sla_items/1.json
  def show
  end

  # GET /sla_items/new
  def new
    @sla_item = SlaItem.new
  end

  # GET /sla_items/1/edit
  def edit
  end

  # POST /sla_items
  # POST /sla_items.json
  def create
    @sla_item = SlaItem.new(sla_item_params)

    respond_to do |format|
      if @sla_item.save
        format.html { redirect_to @sla_item, notice: 'Sla item was successfully created.' }
        format.json { render :show, status: :created, location: @sla_item }
      else
        format.html { render :new }
        format.json { render json: @sla_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sla_items/1
  # PATCH/PUT /sla_items/1.json
  def update
    respond_to do |format|
      if @sla_item.update(sla_item_params)
        format.html { redirect_to @sla_item, notice: 'Sla item was successfully updated.' }
        format.json { render :show, status: :ok, location: @sla_item }
      else
        format.html { render :edit }
        format.json { render json: @sla_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sla_items/1
  # DELETE /sla_items/1.json
  def destroy
    @sla_item.destroy
    respond_to do |format|
      format.html { redirect_to sla_items_url, notice: 'Sla item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sla_item
      @sla_item = SlaItem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sla_item_params
      params.require(:sla_item).permit(:bid_id, :timestamp, :interval_id, :volume, :price)
    end
end
