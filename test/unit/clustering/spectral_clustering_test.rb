require 'test_helper'
require 'test_helper_with_prosumption_data'
require 'clustering/spectral_clustering'

class SpectralClusteringTest < ActiveSupport::TestCaseWithProsumptionData

  test "should create positive error spectral clustering" do
    spek = ClusteringModule::PositiveErrorSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create negative error spectral clustering" do
    spek = ClusteringModule::NegativeErrorSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create positive consumption spectral clustering" do
    spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  test "should create negative consumption spectral clustering" do
    spek = ClusteringModule::NegativeConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @trainend)
    check_performance spek
  end

  def check_performance(clusteringModule)
    failed = 0
    2.upto(9) do |i|
      assert_difference('Clustering.count') do
        cl = Clustering.new(name: "Spectral k=#{i}", temp_clusters: clusteringModule.run(i))
        cl.save
        assert_equal(cl.temp_clusters.count, i)
        Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
        stats = clusteringModule.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
        Rails.logger.debug "#{stats}"
        failed += 1 if stats[:ingroup] < stats[:outgroup]
      end
    end
    assert_operator(failed, :<, 3)
  end

end