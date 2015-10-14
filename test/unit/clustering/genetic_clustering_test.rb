require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/genetic_error_clustering2'
require 'clustering/spectral_clustering'
require 'clustering/evaluate'

class GeneticClusteringTest < ActiveSupport::TestCaseWithProsAndMarketData
  test "should create genetic clustering" do

    skip('Test is too slow, so it is excluded. Remove this line to enable')

    spek1 = ClusteringModule::CrossCorrelationErrorClustering.new(prosumers: @prosumers,
                                                        startDate: @startdate,
                                                        endDate: @trainend)
    spek2 = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers,
                                                                 startDate: @startdate,
                                                                 endDate: @trainend)

    clg1 = Clustering.new(name: "Genetic", temp_clusters: spek1.run(5))
    clg1.save

    clg2 = Clustering.new(name: "Genetic", temp_clusters: spek2.run(5))
    clg2.save


    # clg.temp_clusters.each{|tc| tc.save}


    puts ">>>>>>>>>>>>> #{clg1.temp_clusters.first.prosumers.class}"
    puts "<<<<<<<<<<<<< #{clg2.temp_clusters.first.prosumers.class}"

    puts ">>>>>>>>>>>>> Found #{DataPoint.where(prosumer: clg1.temp_clusters.first.prosumers.map{|p| p.id}, timestamp: @startdate .. @enddate).count } datapoints"
    puts ">>>>>>>>>>>>> Found #{DataPoint.where(prosumer: clg1.temp_clusters.first.prosumers, timestamp: @startdate .. @enddate).count } datapoints"

    puts "<<<<<<<<<<<<< Found #{DataPoint.where(prosumer: clg2.temp_clusters.first.prosumers.map{|p| p.id}, timestamp: @startdate .. @enddate).count } datapoints"
    puts "<<<<<<<<<<<<< Found #{DataPoint.where(prosumer: clg2.temp_clusters.first.prosumers, timestamp: @startdate .. @enddate).count } datapoints"


    puts ">>>>>>>>>>>>> ", Market::Calculator.new(prosumers: clg1.temp_clusters.first.prosumers,
                           startDate: @startdate,
                           endDate: @enddate)
        .calcCosts[:dissagrgated]

    puts "<<<<<<<<<<<<< ", Market::Calculator.new(prosumers: Prosumer.where(id: clg2.temp_clusters.first.prosumers.map{|p| p.id}),
                                startDate: @startdate,
                                endDate: @enddate)
             .calcCosts[:dissagrgated]

=begin
    eval = ClusteringModule::Evaluator.new(
        clusters: clg.temp_clusters,
        startDate: @startdate,
        endDate: @enddate,
        adaptive: false,
        interval: 1.week,
        outputFile: "results/test_genetic_",
        runs: 1
    )

    eval.evaluate
=end


  end
end