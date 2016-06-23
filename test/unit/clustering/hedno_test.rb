require 'test_helper'
require 'test_helper_with_hedno_data'
require 'clustering/spectral_clustering'

class HednoTest < ActiveSupport::TestCaseWithHednoData

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test "prosumers imported" do
    assert_equal 90, @prosumers.count, "We should have 90 prosumers"
  end

  test "count datapoints" do
    # puts JSON.pretty_generate @prosumers.map {|p| [p.id, p.data_points.count]}
    assert (DataPoint.where(prosumer: @prosumers).count.between?(90*(24*4*365 - 1), 90*24*4*365)), "We should have a full datapoint set"
  end

  test "Run spectral clustering on hedno dataset" do
    ActiveRecord::Base.transaction do
      spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @enddate)
      cl = Clustering.new(name: "Spectral", temp_clusters: spek.run(5))
      cl.save
      assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
      Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
      stats = spek.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
      Rails.logger.debug "#{stats}"
    end
  end
end