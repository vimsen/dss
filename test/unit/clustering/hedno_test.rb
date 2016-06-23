require 'test_helper'
require 'test_helper_with_hedno_data'

class HednoTest < ActiveSupport::TestCaseWithHednoData

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test "prosumers imported" do
    assert_equal 90, @prosumers.count, "We should have 79 prosumers"
  end

  test "count datapoints" do

    puts JSON.pretty_generate @prosumers.map {|p| [p.id, p.data_points.count]}
    assert_equal 90*24*4*365, DataPoint.where(prosumer: @prosumers).count, "We should have a full datapoint set"
  end


end