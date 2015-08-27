require 'clustering/evaluate'
clg = Clustering.find(52)
eval = ClusteringModule::Evaluator.new(
            clusters: clg.temp_clusters, 
            startDate: '1/7/2015 00:00:00 +200'.to_datetime, 
            endDate: '8/7/2015 00:00:00 +200'.to_datetime, 
            interval: 1.day,
            adaptive: true)
eval.evaluate

