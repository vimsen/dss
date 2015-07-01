require 'clustering/evaluate'
clg = Clustering.find(41)
eval = ClusteringModule::Evaluator.new(
            clusters: clg.temp_clusters, 
            startDate: '20/6/2015 00:00:00 +200'.to_datetime, 
            endDate: '21/6/2015 00:00:00 +200'.to_datetime, 
            interval: 2.hours,
            adaptive: true)
eval.evaluate

