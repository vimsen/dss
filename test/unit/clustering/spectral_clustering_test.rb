require 'test_helper'
require 'clustering/spectral_clustering'

class SpectralClusteringTest < ActionController::TestCase

  test "should create spectral clustering" do

    ed = DateTime.now
    sd = ed - 1.week

    prosumers = 1.upto(37).map do |i|
       Prosumer.create(intelen_id: i)
    end

    puts "#{prosumers.map{|p| [p.id, p.intelen_id]}}"

    prosumers.each_slice(5) do |p|
      puts "#{p.map{|p| [p.id, p.intelen_id]}}"
      begin
        FetchAsynch::DownloadAndPublish.new(p , 2, sd, ed, nil, true)
      rescue
        puts "Failed to downlad data"

      end
    end

    spek = ClusteringModule::SpectralClustering.new(prosumers: prosumers, startDate: sd, endDate: ed)

    1.upto(9) do |i|

      puts Clustering.count
      assert_difference('Clustering.count') do
        cl = Clustering.new(name: "Spectral k=#{i}", temp_clusters: spek.run(i))
        cl.save
        assert_equal(cl.temp_clusters.count, i)
        puts Clustering.count
        Clustering.count
      end
      puts Clustering.count
    end

  end

end