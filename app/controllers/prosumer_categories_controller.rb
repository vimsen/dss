class ProsumerCategoriesController < ApplicationController
  before_action :set_prosumer_category, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource

  # GET /prosumer_categories
  # GET /prosumer_categories.json
  def index
    @prosumer_categories = ProsumerCategory.all
  end

  # GET /prosumer_categories/1
  # GET /prosumer_categories/1.json
  def show
  end

  # GET /prosumer_categories/new
  def new
    @prosumer_category = ProsumerCategory.new
  end

  # GET /prosumer_categories/1/edit
  def edit
  end

  # POST /prosumer_categories
  # POST /prosumer_categories.json
  def create
    @prosumer_category = ProsumerCategory.new(prosumer_category_params)

    respond_to do |format|
      if @prosumer_category.save
        format.html { redirect_to @prosumer_category, notice: 'Prosumer category was successfully created.' }
        format.json { render :show, status: :created, location: @prosumer_category }
      else
        format.html { render :new }
        format.json { render json: @prosumer_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prosumer_categories/1
  # PATCH/PUT /prosumer_categories/1.json
  def update
    respond_to do |format|
      if @prosumer_category.update(prosumer_category_params)
        format.html { redirect_to @prosumer_category, notice: 'Prosumer category was successfully updated.' }
        format.json { render :show, status: :ok, location: @prosumer_category }
      else
        format.html { render :edit }
        format.json { render json: @prosumer_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prosumer_categories/1
  # DELETE /prosumer_categories/1.json
  def destroy
    @prosumer_category.destroy
    respond_to do |format|
      format.html { redirect_to prosumer_categories_url, notice: 'Prosumer category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prosumer_category
      @prosumer_category = ProsumerCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def prosumer_category_params
      params.require(:prosumer_category).permit(:name, :description, :real_time)
    end
end
