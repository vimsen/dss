

require 'clustering/dss_clustering'

class ConfigurationsController < ApplicationController

 	before_action :set_configuration, only: [:show, :edit, :update, :destroy, :execute]
  #load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  	def index
  		@configurations = ::Configuration.all.order(sort_column + ' ' + sort_direction).paginate(page: params[:page])
  	end

  	def new
    	@configuration = ::Configuration.new
  	  @kappa = ""
      @penalty_violation = ""
      @penalty_satisfaction = ""
      @population_size = ""
      @generations = ""

    end

  	def edit
  	 
      input_params = ActiveSupport::JSON.decode(@configuration.params)

      @kappa = input_params["kappa"]
      @penalty_violation = input_params["penalty_violation"]
      @penalty_satisfaction = input_params["penalty_satisfaction"]
      @population_size = input_params["population_size"]
      @generations = input_params["generations"]

    end

  	def show
  	end

  	def create
    	
      input_parameters = Hash.new
      input_parameters[:kappa] = params[:kappa]
      input_parameters[:penalty_violation] = params[:penalty_violation].to_f
      input_parameters[:penalty_satisfaction] = params[:penalty_satisfaction].to_f 
      input_parameters[:population_size] = params[:population_size].to_i  
      input_parameters[:generations] = params[:generations].to_i
   
      @configuration = ::Configuration.new
      @configuration[:name] = params[:configuration][:name]
      @configuration[:algorithm_id] = params[:algorithm_id].to_i
      @configuration[:user_id] = session["warden.user.user.key"][0][0]
      @configuration[:params] = input_parameters.to_json
    
    	respond_to do |format|
      		if @configuration.save
        		format.html do
          			redirect_to configurations_url, notice: 'Configuration was successfully created.'
        		end
      		else
        		format.html { render :new }
        		format.json do
          			render json: @configuration.errors, status: :unprocessable_entity
        		end
      		end
    	end
  	end

    def update
  
      input_parameters = Hash.new
      input_parameters[:kappa] = params[:kappa]
      input_parameters[:penalty_violation] = params[:penalty_violation].to_f
      input_parameters[:penalty_satisfaction] = params[:penalty_satisfaction].to_f 
      input_parameters[:population_size] = params[:population_size].to_i  
      input_parameters[:generations] = params[:generations].to_i
   
      @configuration[:name] = params[:configuration][:name]
      @configuration[:algorithm_id] = params[:algorithm_id].to_i
      @configuration[:params] = input_parameters.to_json
    
      respond_to do |format|
      
      if @configuration.save
        format.html do
          redirect_to configurations_url, notice: 'Configuration was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @prosumer }
      else
        format.html { render :edit }
        format.json do
          render json: @configuration.errors, status: :unprocessable_entity
        end
      end
    end

    end

    def destroy
      @configuration.destroy
      respond_to do |format|
        format.html do
          redirect_to configurations_url, notice: 'Configuration was successfully destroyed.'
        end
        format.json { head :no_content }
      end    
    end

    def execute

      sqs = Aws::SQS::Client.new(region: ENGINE_CONFIG[:aws][:region], access_key_id: ENGINE_CONFIG[:aws][:access_key_id], secret_access_key: ENGINE_CONFIG[:aws][:secret_access_key])         
    
      instance = Instance.new
    
      instance[:user_id] = session["warden.user.user.key"][0][0]
      instance[:configuration_id] = @configuration[:id]
      instance[:status] = 0 
      instance[:instance_name] = @configuration[:name]+"_"+Time.now.to_i.to_s
      instance.save

      input_params = ActiveSupport::JSON.decode(@configuration.params)

      cluster = ClusteringModule::GeneticErrorClustering.new({
        :penalty_violation => input_params["penalty_violation"],
        :penalty_satisfaction => input_params["penalty_satisfaction"], 
        :population_size => input_params["population_size"],
        :generations => input_params["generations"]
      })

      cluster.prepare_input_dataset(instance[:id], input_params["kappa"].to_i) 

      cmd = Hash.new

      cmd[:action] = "start"
      cmd[:instance_id] = instance[:id]
      cmd[:configuration_id] = instance[:configuration_id]
      cmd[:user_id] = instance[:user_id]

      resp = sqs.send_message(queue_url: ENGINE_CONFIG[:aws][:request_queue_url], message_body:  Base64.encode64(cmd.to_json))

      redirect_to configurations_url, notice: 'Configuration was successfully executed.'

    end

    private

       # Use callbacks to share common setup or constraints between actions.
       def set_configuration
    	  @configuration = ::Configuration.find(params[:id])
       end

       # Never trust parameters from the scary internet, only allow the white list
       # through.
       def configuration_params
         params.require(:configuration).permit(:name, :algorithm_id, :parameters)
       end

       def sort_column
        'name'
       end

       def sort_direction
         %w(asc desc).include?(params[:direction]) ?  params[:direction] : 'asc'
       end

end

