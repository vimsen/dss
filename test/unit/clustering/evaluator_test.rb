require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/evaluate'
require 'clustering/spectral_clustering'
require 'clustering/genetic_error_clustering2'

class EvaluatorTest < ActiveSupport::TestCaseWithProsAndMarketData
  test "should create evaluation results" do

    skip('Test is too slow, so it is excluded. Remove this line to enable')
    
    # 10.times do |round|
    1.times do |round|

      { genetic: ClusteringModule::GeneticErrorClustering,
        # pos_error: ClusteringModule::PositiveErrorSpectralClustering,
        # neg_error: ClusteringModule::NegativeErrorSpectralClustering,
        # pos_cons: ClusteringModule::PositiveConsumptionSpectralClustering,
        # neg_cons: ClusteringModule::NegativeConsumptionSpectralClustering
      }.each do |(name, cl)|

        spek = cl.new(prosumers: @prosumers,
                      startDate: @startdate,
                      endDate: @trainend)

        clg = Clustering.new(name: name, temp_clusters: spek.run(5))
        clg.save


        puts "#{clg.temp_clusters.map{|tc| tc.prosumers.map{|p| p.id}}}"

        eval = ClusteringModule::Evaluator.new(
            clusters: clg.temp_clusters,
            startDate: @startdate,
            endDate: @enddate,
            adaptive: false,
            interval: 1.week,
            outputFile: "results/test_#{name}_#{round}_",
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
