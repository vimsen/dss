require 'test_helper_with_prosumption_data'

class ActiveSupport::TestCaseWithProsAndMarketData < ActiveSupport::TestCaseWithProsumptionData
  setup do
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


