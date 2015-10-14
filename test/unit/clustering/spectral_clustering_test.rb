require 'test_helper'
require 'test_helper_with_prosumption_data'
require 'clustering/spectral_clustering'

class SpectralClusteringTest < ActiveSupport::TestCaseWithProsumptionData

  test "should create Cross-correlation error spectral clustering" do
    spek = ClusteringModule::PositiveErrorSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create inverse Cross-correlation error spectral clustering" do
    spek = ClusteringModule::NegativeErrorSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create Cross-correlation consumption spectral clustering" do
    spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create inverse Cross-correlation consumption spectral clustering" do
    spek = ClusteringModule::NegativeConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  def check_performance clusteringModule
    2.upto(9) do |i|
      assert_difference('Clustering.count') do
        cl = Clustering.new(name: "Spectral k=#{i}", temp_clusters: clusteringModule.run(i))
        cl.save
        assert_equal(cl.temp_clusters.count, i)
        puts "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
        stats = clusteringModule.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
        puts "#{stats}"
        assert_operator(stats[:ingroup], :>, stats[:outgroup])
        Clustering.count
      end
    end
  end

end