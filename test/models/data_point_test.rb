require 'test_helper'
require 'test_helper_with_prosumption_data'

class DataPointTest < ActiveSupport::TestCaseWithProsumptionData

  test "DataPoints should have 16266 data_points" do
    assert_equal 30944, DataPoint.count

    @prosumers.each do |p|
      puts "#{p.id}: #{p.name}: #{p.intelen_id}: #{p.data_points.where(interval: 2).count}"
    end
  end



#  test "the truth" do
#     assert true
#  end
end
