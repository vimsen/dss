require 'test_helper'
require 'test_helper_with_prosumption_data'
require 'clustering/spectral_clustering'

class SpectralClusteringTest < ActiveSupport::TestCaseWithProsumptionData

  test "should create spectral clustering" do

    ed = '2015/3/30'
    sd = '2015/3/23'

    spek = ClusteringModule::SpectralClustering.new(prosumers: @prosumers, startDate: sd, endDate: ed)

    2.upto(9) do |i|
      assert_difference('Clustering.count') do
        cl = Clustering.new(name: "Spectral k=#{i}", temp_clusters: spek.run(i))
        cl.save
        assert_equal(cl.temp_clusters.count, i)
        puts "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
        stats = spek.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
        puts "#{stats}"
        assert_operator(stats[:ingroup], :>, stats[:outgroup])
        Clustering.count
      end
    end

  end

end