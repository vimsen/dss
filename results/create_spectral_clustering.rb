require 'clustering/spectral_clustering'
sd = '24/3/2015 00:00:00 +200'.to_datetime
ed = '31/3/2015 00:00:00 +200'.to_datetime
spek = ClusteringModule::CrossCorrelationErrorClustering.new(startDate: sd, endDate: ed)
cl = Clustering.new(name: "Spectral 24/3/2015-31/3/2015", temp_clusters: spek.run(5))
cl.save
exit
