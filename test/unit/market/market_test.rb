require 'test_helper'
require 'test_helper_with_pros_and_market_data'

class MarketTest < ActiveSupport::TestCaseWithProsAndMarketData

  setup do
    @enddate = DateTime.now
    @startdate = @enddate - 3.days
    @prosumers = [Prosumer.find_by(edms_id: "b827eb725029")]
    # @prosumers = [Prosumer.find_by(edms_id: 1)]
    # @prosumers = Prosumer.all

    FetchAsynch::DownloadAndPublish.new prosumers: @prosumers,
                                        interval: Interval.find_by_duration(3600).id,
                                        startdate: @startdate,
                                        enddate: @enddate,
                                        channel: nil,
                                        async: true
  end

  test "Should calculate market data" do

    costs = Market::Calculator.new(prosumers: @prosumers,
                                   startDate: @startdate,
                                   endDate: @enddate).calcCosts

    # puts JSON.pretty_generate costs

  end

end