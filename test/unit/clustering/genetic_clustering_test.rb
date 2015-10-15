require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/genetic_error_clustering2'
require 'clustering/spectral_clustering'
require 'clustering/evaluate'

class GeneticClusteringTest < ActiveSupport::TestCaseWithProsAndMarketData
  test "should create genetic clustering" do

   #  skip('Test is too slow, so it is excluded. Remove this line to enable')

    spek = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers,
                                                                 startDate: @startdate,
                                                                 endDate: @trainend)

    clg = Clustering.new(name: "Genetic", temp_clusters: spek.run(5))
    clg.save

    puts Market::Calculator.new(prosumers: clg.temp_clusters.first.prosumers,
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