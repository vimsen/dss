require 'clustering/evaluate'
clg = Clustering.find(41)
eval = ClusteringModule::Evaluator.new(
            clusters: clg.temp_clusters, 
            startDate: '30/3/2015 00:00:00 +200'.to_datetime, 
            endDate: '30/5/2015 00:00:00 +200'.to_datetime, 
            adaptive: true)
eval.evaluate

