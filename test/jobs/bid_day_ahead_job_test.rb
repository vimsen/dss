require 'test_helper'

class BidDayAheadJobTest < ActiveJob::TestCase
  test "task should run" do
    BidDayAheadJob.perform_now
    assert true
  end
end
