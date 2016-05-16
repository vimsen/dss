require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/evaluate'
require 'clustering/genetic_error_clustering2'

class EmergiTest < ActiveSupport::TestCaseWithProsAndMarketData

  test "should evaluate iterative clustering" do

    skip "Don't spoil simulation results"
    10.times do |k|
      File.open("results/emergi_#{k}", "w") do |f|
        10.times do |i|
          spek = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers,
                                                              startDate: @startdate,
                                                              endDate: @trainend + i.weeks,
                                                              generations: 100)
          clg = Clustering.new(name: "Genetic", temp_clusters: spek.run(5))
          clg.save

          stats = clg.temp_clusters.map do |tc|
            penalty_before = 0
            penalty_after = 0
            Market::Calculator.new(prosumers: tc.prosumers,
                                   startDate: @trainend + i.weeks,
                                   endDate: @trainend + (i+1).weeks)
                .calcCosts[:dissagrgated].each do |v|
              penalty_before = v[:real] - v[:ideal] if v[:name] == :sum
              penalty_after = v[:real] - v[:ideal] if v[:name] == "aggr."
            end
            {pb: penalty_before, pa: penalty_after}
          end

          puts JSON.pretty_generate stats

          f.write "#{i}\t" + stats.map{|s| (s[:pb] - s[:pa]) / s[:pb]}.sort.reverse.join("\t")

          total_pb = stats.sum{|s| s[:pb]}
          total_pa = stats.sum{|s| s[:pa]}

          f.puts "\t#{(total_pb - total_pa) / total_pb}"
          f.flush
        end
      end
    end
  end

  test "print week dates" do
    skip "Pointless test"
    10.times do |i|
      puts "i: #{i}, tr_start: #{@startdate}, tr_end: #{@trainend + i.weeks}, start: #{@trainend + i.weeks}, end: #{@trainend + (i+1).weeks}"
    end
  end
end
