require 'clustering/evaluate'
clg = Clustering.find(41)
eval = ClusteringModule::Evaluator.new(clusters: clg.temp_clusters, startDate: '24/3/2015 00:00:00 +200'.to_datetime, adaptive: true)
eval.evaluate

