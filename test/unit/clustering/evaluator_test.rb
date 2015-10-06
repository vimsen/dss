require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/evaluate'
require 'clustering/spectral_clustering'

class EvaluatorTest < ActiveSupport::TestCaseWithProsAndMarketData
  test "should create evaluation results" do

    training_ed = '2015/3/30'
    training_sd = '2015/3/23'

    spek = ClusteringModule::SpectralClustering.new(prosumers: @prosumers,
                                                    startDate: training_sd,
                                                    endDate: training_ed)

    clg = Clustering.new(name: "Spectral", temp_clusters: spek.run(5))
    clg.save

    puts "#{clg.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"

    eval = ClusteringModule::Evaluator.new(
        clusters: clg.temp_clusters,
        startDate: '23/3/2015 00:00:00 +200'.to_datetime,
        endDate: '25/5/2015 00:00:00 +200'.to_datetime,
        adaptive: false,
        interval: 1.week,
        outputFile: 'results/test_',
        runs: 1
    )

    eval.evaluate

    eval.instance_variable_get(:@runs).times do |i|
      CSV.foreach("results/test_#{i}.csv", headers: true, col_sep: "\t")
          .with_index do |row, i|
        assert_equal i, row[0].to_i
        assert_operator row.reject{|k,v| k == "week"}.map{|k,v| v.to_f}.max, :>, 10
      end
      # assert_file "results/test_#{i}_before.csv"
      # assert_file "results/test_#{i}_after.csv"
    end


  end
end