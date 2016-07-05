require 'test_helper'
require 'test_helper_with_hedno_data'
require 'clustering/spectral_clustering'
require 'clustering/genetic_error_clustering2'

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
    assert_equal 440, @prosumers.count, "We should have 440 prosumers"
  end

  test "count pv_lv_hedno datapoints" do
    assert_equal 40*(24*4*365-1), DataPoint.where(prosumer: 3000..4000).count, "pv_lv_hedno"
  end

  test "count aiolika_MV datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 4000..5000).count, "aiolika_MV"
  end

  test "count emporikoi_MV datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 5000..6000).count, "emporikoi_MV"
  end

  test "count biomhxanikoi datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 6000..7000).count, "biomhxanikoi"
  end

  test "count biomhxanikoi_MV datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 7000..8000).count, "biomhxanikoi_MV"
  end

  test "count epaggelmatikoi datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 8000..9000).count, "epaggelmatikoi"
  end

  test "count fwtismos_odwn_plateiwn datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 9000..10000).count, "fwtismos_odwn_plateiwn"
  end

  test "count oikiakoi datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 10000..11000).count, "oikiakoi"
  end

  test "count photovoltaika_MV datapoints" do
    assert_equal 50*24*4*365, DataPoint.where(prosumer: 11000..12000).count, "photovoltaika_MV"
  end
      # puts JSON.pretty_generate @prosumers.map {|p| [p.id, p.data_points.count]}
  #  assert (DataPoint.where(prosumer: @prosumers).count.between?(240*(24*4*365 - 1), 240*24*4*365)), "We should have a full datapoint set"
  # end

  test "Run spectral clustering on hedno dataset" do
    spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @enddate)
    cl = Clustering.new(name: "Spectral", temp_clusters: spek.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    stats = spek.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
    Rails.logger.debug "#{stats}"
  end

  test "Run genetic clustering on hedno dataset" do
    gen = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @enddate)
    cl = Clustering.new(name: "Genetic", temp_clusters: gen.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    Rails.logger.debug Market::Calculator.new(prosumers: cl.temp_clusters.first.prosumers,
                                              startDate: @startdate,
                                              endDate: @enddate)
                                         .calcCosts[:dissagrgated]
  end
end