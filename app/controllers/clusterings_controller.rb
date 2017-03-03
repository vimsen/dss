require 'clustering/clustering_module'
require 'market/market'

# This is the controller handles the automatic clustring BL
class ClusteringsController < ApplicationController

  before_action :set_clustering, only: [:show, :edit, :update, :destroy, :apply]

  load_and_authorize_resource

#  skip_authorize_resource :only => [:select, :confirm]

  respond_to :json, :html
#  authorize_resource class: false

  def index
    @clusterings = Clustering.all
  end

  def show

    session_obj = JSON.parse session[:algo_params] || "{}"
    session_obj["startDate"] = @startDate = (params["startDate"] || session_obj["startDate"])&.to_datetime || DateTime.now - 7.days
    session_obj["endDate"] = @endDate = (params["endDate"] || session_obj["endDate"])&.to_datetime || DateTime.now
    session_obj["internalDr"] = @internalDr = ((params["internalDr"] || session_obj["internalDr"]) == "true") || false

    session[:algo_params] = session_obj.to_json



    @stats = @clustering.temp_clusters.map do |tc|
                    [tc.id, Hash[Market::Calculator.new(prosumers: tc.prosumers, startDate: @startDate, endDate: @endDate)
                                     .calcCosts2(dr: @internalDr)[:disaggregated]
                                     .select { |d| d[:id] < 0 }
                                     .map { |d| [d[:id], d.dup.update(penalty: d[:real] - d[:ideal])] }]]

                  end.to_h

    @sum_sum = @stats.sum { |k,v| v[-1][:real]}
    @pen_sum = @stats.sum { |k,v| v[-1][:penalty]}
    @sum_aggr = @stats.sum { |k,v| v[-2][:real]}
    @pen_aggr = @stats.sum { |k,v| v[-2][:penalty]}

    @idata = @clustering.temp_clusters.map do |tc|
      v = @internalDr ? [{
          label: :dr,
          data: DataPoint.joins("LEFT JOIN forecasts ON forecasts.timestamp = data_points.timestamp AND data_points.prosumer_id = forecasts.prosumer_id AND data_points.interval_id = forecasts.interval_id")
                    .where(timestamp: @startDate .. @endDate, interval: 2, prosumer: tc.prosumers)
                    .group(:timestamp)
                    .order(timestamp: :asc)
                    .select(
                        :timestamp,
                        "CASE (sum(coalesce(forecasts.consumption,0) - coalesce(forecasts.production,0)) > sum(coalesce(data_points.consumption,0) - coalesce(data_points.production,0)))
                                    WHEN TRUE THEN
                                      sum(coalesce(data_points.consumption,0) - coalesce(data_points.production,0))
                                    ELSE
                                      GREATEST(sum((( (1.0-coalesce(data_points.dr,0))*coalesce(data_points.consumption,0) - coalesce(data_points.production,0)))),sum(coalesce(forecasts.consumption,0) - coalesce(forecasts.production,0)))
                                    END as dr_curve"
                    ).map{|d| [d.timestamp.to_i * 1000, d.dr_curve]}
                         }]: []
      {
          id: tc.id,
          vals: [{
                     label: :prosumption,
                     data: DataPoint.where(prosumer: tc.prosumers,
                                           interval: 2,
                                           timestamp: @startDate..@endDate)
                               .order("ts ASC")
                               .group(:ts)
                               .select("timestamp as ts, sum(COALESCE(consumption,0) - COALESCE(production,0)) as s")
                               .map{|p| [p.ts.to_datetime.to_i * 1000, p.s] }
                 },{
                     label: :forecast,
                     data: Forecast.day_ahead.where(prosumer: tc.prosumers,
                                                    interval: 2,
                                                    timestamp: @startDate..@endDate)
                               .order("ts ASC")
                               .group(:ts)
                               .select("timestamp as ts, sum(COALESCE(consumption,0) - COALESCE(production,0)) as s")
                               .map{|p| [p.ts.to_datetime.to_i * 1000, p.s] }
                 },{
                     label: "",
                     data: [[@startDate.to_i * 1000,0]],
                     points: { show: false }
                 }] + v
      }
    end

  end

  def new
    @clustering = Clustering.new
    @clustering.temp_clusters.build
    respond_with(@clustering)
  end

  def new_from_existing
    @clustering = Clustering.new(name: "From existing",
                                 description: "Clustering generated from existing clusters at #{Time.now}")
    Cluster.all.each do |c|
      @clustering.temp_clusters << TempCluster.new(name: c.name,
                                                   description: c.description,
                                                   prosumers: c.prosumers,
                                                   clustering: @clustering)
    end
    puts "CLUSTERING=====", @clustering
    respond_with(@clustering)
  end

  def edit

  end

  def create
    @clustering = Clustering.new(clustering_params)
    if @clustering.save
      flash[:notice] = 'Clustering was successfully created.'
    else
      flash[:error] = 'Clustering was NOT successfully created.'
    end
    respond_with(@clustering)
  end

  def update
    ActiveRecord::Base.transaction do
      clusterids = params[:clustering][:temp_clusters_attributes];

      if clusterids.nil?
        @clustering.temp_clusters.destroy_all
      else
        @clustering.temp_clusters.where.not(id: clusterids.map { |k, v| v["id"] }).destroy_all
      end

      if @clustering.update(clustering_params)
        flash[:notice] = 'Clustering was successfully updated'
      else
        flash[:error] = 'Clustering was NOT successfully updated'
      end
      respond_with(@clustering)
    end
  end

  def destroy
    @clustering.destroy
    respond_with(@clustering)
  end

  def select
    # puts "session is: #{session[:algo_params]}"
    @params = JSON.parse session[:algo_params] || "{}"
    init_algo_params!(@params)
  end

  def confirm

    # puts "Received params: #{params}"
    init_algo_params!(params)
    session[:algo_params] = JSON.generate params

    @clustering = Clustering.new(name: "Auto #{params[:algorithm]}",
                                 description: "Automatic cluster generated with #{params[:algorithm]} algorithm.")
    @clustering.temp_clusters = ClusteringModule.run_algorithm params
  end

  def apply
    ActiveRecord::Base.transaction do
      Cluster.destroy_all

      Cluster.create(
          @clustering.temp_clusters.map do |tc|
            {
                name: tc.name,
                description: tc.description,
                prosumers: tc.prosumers
            }
          end
      )
    end
    redirect_to clusters_path, notice: 'Clustering was applied'
  end

  helper_method :algorithms

  private

  def algorithms
    ClusteringModule.algorithms
  end

  def set_clustering
    @clustering = Clustering.find(params[:id])
  end

  def clustering_params
    result = params.require(:clustering).permit(
        :name,
        :description,
        :temp_clusters_attributes => [
            :id,
            :name,
            :description,
            :_destroy
        ]
    )
    unless params[:clusterprosumers].nil?
      result["temp_clusters_attributes"]
          .zip(params[:clusterprosumers]).each do |tca, pros_list|
        tca[1]["prosumers"] = Prosumer.find(pros_list.split(','))
      end
    end
    return result
  end



  def init_algo_params!(params)
    params["category"] ||= [ ProsumerCategory.first.id ]
    params["algorithm"] ||= algorithms.keys[0]
    params["kappa"] ||= 5
    params["startDate"] ||= (DateTime.now - 7.days)
    params["endDate"] ||= DateTime.now
  end
end
