require 'test_helper_with_prosumption_data'

module MarketData
  def load_market_data
    puts "Importing market data"
    if DayAheadEnergyPrice.count < 37
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      raw.copy_data "COPY day_ahead_energy_prices (id, date, dayhour, price, region_id, created_at, updated_at) FROM stdin;" do
        c = 0
        File.open("test/fixtures/day_ahead.sql", 'r').each do |line|
          c = c + 1
          raw.put_copy_data line if c > 1
        end
        # raw.put_copy_data File.read("../prosumers.sql")
      end
      ActiveRecord::Base.connection_pool.checkin(dbconn)
      puts "We have #{DayAheadEnergyPrice.count} prices"
    end
    puts "Market Data created."
  end
end

class ActiveSupport::TestCaseWithProsAndMarketData < ActiveSupport::TestCaseWithProsumptionData
  include MarketData

  setup do
    load_market_data
  end

end

class ActionController::TestCaseWithProsAndMarketData < ActionController::TestCaseWithProsumptionData
  include MarketData

  setup do
    load_market_data
  end

end

class ActionDispatch::IntegrationTestWithProsAndMarketData < ActionDispatch::IntegrationTestWithProsumptionData
  include MarketData

  setup do
    load_market_data
  end

end