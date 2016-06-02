module HednoData
  def load_prosumption_data
    Rails.logger.debug "Importing HEDNO prosumers"
    @prosumers = Prosumer.create(1.upto(40).map do |i|
      {id: i, name: "pr #{i}", edms_id: i+100000}
    end)
    Rails.logger.debug "Prosumer ids: #{@prosumers.map{|p| p.name}}"
    Rails.logger.debug "Prosumer ids3: #{Prosumer.all.map{|p| p.name}}"

    Rails.logger.debug "Importing datapoints"
    dbconn = ActiveRecord::Base.connection_pool.checkout
    raw  = dbconn.raw_connection

    raw.copy_data "COPY data_points (prosumer_id, interval_id, "\
                "timestamp, production) FROM stdin;" do
      c = 0
      File.open("test/fixtures/pv_lv_hedno.sql", 'r').each do |line|
        c = c + 1
        raw.put_copy_data line if c > 1
      end
    end
    ActiveRecord::Base.connection_pool.checkin(dbconn)
    Rails.logger.debug "We have #{DataPoint.count} data points"

    @startdate = '2015/1/1'.to_datetime
    @enddate = '2015/12/31'.to_datetime

    Rails.logger.debug "data imported, #{@prosumers.count} prosumers with valid training data"
    Rails.logger.debug "First prosumer has #{@prosumers.first.data_points.count} datapoints , last one has #{@prosumers.last.data_points.count}"
    Rails.logger.debug "max: #{@prosumers.first.data_points.max}, min: #{@prosumers.last.data_points.min}"

  end
end

class ActiveSupport::TestCaseWithHednoData < ActiveSupport::TestCase
  include HednoData

  setup do
    load_prosumption_data
  end

end

class ActionController::TestCaseWithHednoData < ActionController::TestCase
  include HednoData

  setup do
    load_prosumption_data
  end

end

class ActionDispatch::IntegrationTestWithHednoData < ActionDispatch::IntegrationTest
  include HednoData

  setup do
    load_prosumption_data
  end

end

class ActiveJob::TestCaseWithHednoData < ActiveJob::TestCase
  include HednoData

  setup do
    load_prosumption_data
  end

end
