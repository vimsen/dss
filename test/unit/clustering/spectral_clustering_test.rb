require 'test_helper'
require 'clustering/spectral_clustering'

class SpectralClusteringTest < ActionController::TestCase

  test "should create spectral clustering" do

    ed = DateTime.now
    sd = ed - 1.week

    prosumers = 12.upto(37).map do |i|
       Prosumer.create(intelen_id: i)
    end

      puts prosumers.map{|p| [p.id, p.intelen_id]}

    FetchAsynch::DownloadAndPublish.new(prosumers , 2, sd, ed, nil, true)

    spek = ClusteringModule::SpectralClustering.new(prosumers: prosumers, startDate: sd, endDate: ed)

    1.upto(9) do |i|

      puts Clustering.count
      assert_difference('Clustering.count') do
        cl = Clustering.new(name: "Spectral k=#{i}", temp_clusters: spek.run(i))
        cl.save
        puts Clustering.count
        Clustering.count
      end
      puts Clustering.count
    end

  end

end