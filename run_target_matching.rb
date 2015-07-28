require 'clustering/match_expected'
require 'csv'

class TargetMatcherEvaluator

  attr_accessor :tm

  def initialize(options = {})
    @tm = ClusteringModule::TargetMatcher.new(
      startDate: '27/7/2015 0:00:00'.to_datetime,
      endDate: '28/7/2015 0:00:00'.to_datetime,
      targets: options[:targets] || 25.times.map{|d| 8}
    )
  end

  def run
    @tm.run
  end

end

target = 1
targets = []
results = []

plot = []

#9.times do
8.times do |i|

  target_vector = 25.times.map{|d| target}

  targets.push(target_vector.map{ -100 }) if i == 5

  targets.push(target_vector)
  tme = TargetMatcherEvaluator.new(targets: target_vector)
  result = tme.run
  
  results.push(target_vector.map{ -100 }) if i == 5
  results.push(result[:consumption].map{|(a,b)| b})
  
  plot[0] ||= (1 .. target_vector.length).to_a

  target = target * 2 ** 0.5
end
 
plot = plot + targets + results

CSV.open('target1.csv', 'w', col_sep: "\t") do |csv|
  plot.transpose.each do |row|
    csv << row
  end
end

puts JSON.pretty_generate plot

# tme = TargetMatcherEvaluator.new


# puts "The result is #{result[:prosumers].to_json}"

# puts JSON.pretty_generate result[:prosumers].map{|p| p.id}


