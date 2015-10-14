require 'clustering/spectral_clustering'
sd = '24/3/2015 00:00:00 +200'.to_datetime
ed = '31/3/2015 00:00:00 +200'.to_datetime
spek = ClusteringModule::PositiveErrorSpectralClustering.new(startDate: sd, endDate: ed)

#1.upto(5) do |i|
6.upto(9) do |i|
  cl = Clustering.new(name: "Spectral k=#{i} 24/3/2015-31/3/2015", temp_clusters: spek.run(i))
  cl.save
  puts "#{i}, #{cl.id}"
end
