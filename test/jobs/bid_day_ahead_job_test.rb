
require 'test_helper_with_prosumption_data'

class BidDayAheadJobTest < ActiveJob::TestCaseWithProsumptionData
  test "task should run" do

    BidDayAheadJob.perform_now

    assert true
  end
end
