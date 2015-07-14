require 'clustering/evaluate'

# clg = Clustering.find(41) # Genetic
# clg = Clustering.find(40) # Spectral

# clusterings = 53 .. 57 # spectral k
clusterings = 58 .. 62 # genetic k and adaptive k

clusterings.each do |c|

  clg = Clustering.find(c)
  ev = ClusteringModule::Evaluator.new(
            clusters: clg.temp_clusters, 
            startDate: '24/3/2015 00:00:00 +200'.to_datetime, 
            endDate: '30/5/2015 00:00:00 +200'.to_datetime, 
#            startDate: '1/7/2015 00:00:00 +200'.to_datetime, 
#            endDate: '8/7/2015 00:00:00 +200'.to_datetime, 
            interval: 1.week,
            adaptive: true,
            outputFile: "result_adaptive_k_#{clg.temp_clusters.length}_")
  ev.evaluate
end

