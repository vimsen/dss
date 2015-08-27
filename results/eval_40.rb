require 'clustering/evaluate'
clg = Clustering.find(40)
eval = ClusteringModule::Evaluator.new(clusters: clg.temp_clusters, startDate: Time.now - 3.months)
eval.evaluate

