require 'test_helper'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation

class DownloadAndPublishTest < ActiveSupport::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  setup do
    DatabaseCleaner.start
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  teardown do
    DatabaseCleaner.clean
  end

  test "Should download data from old API" do
    enddate = DateTime.now
    startdate = enddate - 24.hours

    prosumer = prosumers(:one)


    FetchAsynch::DownloadAndPublish.new( [prosumer], Interval.find_by_duration(3600).id, startdate, enddate, nil, true)
    # puts Prosumer.first.data_points.count
    validate_data_points(prosumer, Interval.find_by_duration(3600).id, startdate, enddate)

  end

  test "Should download data from new API" do
    enddate = DateTime.now
    startdate = enddate - 24.hours

    prosumer = prosumers(:two)


    FetchAsynch::DownloadAndPublish.new( [prosumer], Interval.find_by_duration(3600).id, startdate, enddate, nil, true)
    # puts Prosumer.first.data_points.count
    validate_data_points(prosumer, Interval.find_by_duration(3600).id, startdate, enddate)


  end

  private
  def validate_data_points(prosumer, interval_id, startdate, enddate)
      assert_equal 24, prosumer.data_points.where(interval_id: interval_id, timestamp: startdate...enddate).count, "We should receive 24 data points"
  end

end