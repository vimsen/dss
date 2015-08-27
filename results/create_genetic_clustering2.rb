require 'clustering/genetic_error_clustering2'
sd = '1/7/2015 00:00:00 +200'.to_datetime
ed = '8/8/2015 00:00:00 +200'.to_datetime
gec = ClusteringModule::GeneticErrorClustering.new(startDate: sd, endDate: ed)
tcs = gec.run(5)
cl = Clustering.new(name: "Genetic 1/7/2015-8/7/2015)", temp_clusters: tcs)
cl.save
