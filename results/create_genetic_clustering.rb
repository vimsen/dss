require 'clustering/genetic_error_clustering2'
sd = '24/3/2015 00:00:00 +200'.to_datetime
ed = '31/3/2015 00:00:00 +200'.to_datetime
gec = ClusteringModule::GeneticErrorClustering.new(startDate: sd, endDate: ed)
tcs = gec.run(5)
cl = Clustering.new(name: "Genetic 24/3/2015-31/3/2015 (2)", temp_clusters: tcs)
cl.save
