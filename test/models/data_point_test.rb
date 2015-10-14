require 'test_helper'
require 'test_helper_with_prosumption_data'

class DataPointTest < ActiveSupport::TestCaseWithProsumptionData

  test "DataPoints should have 16266 data_points" do
    assert_equal 241809, DataPoint.count

    @prosumers.sort_by{ |p| p.name }.each do |p|

      points = (@startdate.to_i .. @enddate.to_i).step(1.week.to_i).map do |secs|
        sd = Time.at(secs)
        ed = sd + 1.week
        p.data_points.where(
            interval: 2,
            timestamp: sd .. ed
        ).where("consumption > ?", 0).count
      end

      puts "#{p.id}: #{p.name}: #{p.intelen_id}: #{points}"
    end

    points = @prosumers.map do |p|
      p.data_points
          .where(interval: 2, timestamp: @startdate .. @trainend)
          .where("consumption > ?", 0)
          .count
    end.sum

    max = @prosumers.count * (@startdate .. @trainend).count * 24

    assert_operator(points, :>, max / 2)

  end



#  test "the truth" do
#     assert true
#  end
end
