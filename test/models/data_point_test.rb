require 'test_helper'
require 'test_helper_with_prosumption_data'

class DataPointTest < ActiveSupport::TestCaseWithProsumptionData

  test "DataPoints should have 16266 data_points" do
    assert_equal 241809, DataPoint.count

    startdate = '2015/3/23'.to_datetime
    enddate = '2015/4/27'.to_datetime

=begin
    @prosumers.sort_by{ |p| p.name }.each do |p|
      puts "#{p.id}: #{p.name}: #{p.intelen_id}: #{p.data_points.where(
               interval: 2,
               timestamp: startdate .. enddate
           ).count}"
    end
=end

    points = @prosumers.map do |p|
      p.data_points.where(
          interval: 2,
          timestamp: startdate .. enddate).count
    end.sum

    max = @prosumers.count * (startdate .. enddate).count * 24

    assert_operator(points, :>, max / 2)

  end



#  test "the truth" do
#     assert true
#  end
end
