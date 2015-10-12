require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/evaluate'
require 'clustering/spectral_clustering'
require 'clustering/genetic_error_clustering2'

class EvaluatorTest < ActiveSupport::TestCaseWithProsAndMarketData
  test "should create evaluation results" do

    1.times do |round|
      1.upto(9) do |kappa|
        { genetic: ClusteringModule::GeneticErrorClustering,
          pos_error: ClusteringModule::CrossCorrelationErrorClustering,
          neg_error: ClusteringModule::InverseCrossCorrelationErrorClustering,
          pos_cons: ClusteringModule::CrossCorrelationConsumptionClustering,
          neg_cons: ClusteringModule::InverseCrossCorrelationConsumptionClustering,
          adaptive: ClusteringModule::GeneticErrorClustering
        }.each do |(name, cl)|

          spek = cl.new(prosumers: @prosumers,
                        startDate: @startdate,
                        endDate: @trainend)

          clg = Clustering.new(name: name, temp_clusters: spek.run(kappa))
          clg.save


          puts "#{clg.temp_clusters.map{|tc| tc.prosumers.map{|p| p.id}}}"

          eval = ClusteringModule::Evaluator.new(
              clusters: clg.temp_clusters,
              startDate: @startdate,
              endDate: @trainend,
              adaptive: (name == :adaptive),
              interval: 1.week,
              outputFile: "results/kappa_#{kappa}_#{name}_#{round}_",
              runs: 1
          )

          eval.evaluate

          eval.instance_variable_get(:@runs).times do |i|
            succ = 0
            total = 0
            CSV.foreach(eval.instance_variable_get(:@outputFile) + "#{i}.csv", headers: true, col_sep: "\t")
                .with_index do |row, i|
              assert_equal i, row[0].to_i
              succ += 1 if row.reject{|k,v| k == "week"}.map{|k,v| v.to_f}.max > 8
              total += 1
            end
            # assert_operator succ, :>, total / 2
            # assert_file "results/test_#{i}_before.csv"
            # assert_file "results/test_#{i}_after.csv"
          end
        end
      end
    end
  end
end