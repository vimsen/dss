require 'clustering/genetic_error_clustering2'
sd = '24/3/2015 00:00:00 +200'.to_datetime
ed = '31/3/2015 00:00:00 +200'.to_datetime
gec = ClusteringModule::GeneticErrorClustering.new(startDate: sd, endDate: ed)

#res = 1.upto(5).map do |i|
res = 6.upto(10).map do |i|
  cl = Clustering.new(name: "Genetic k=#{i} 24/3/2015-31/3/2015", 
                      temp_clusters: gec.run(i))
  cl.save
  [ i, cl.id]
end
res
