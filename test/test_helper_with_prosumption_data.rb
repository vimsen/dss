module ProsumptionData
  def load_prosumption_data
    if @prosumers.nil? || @prosumers.count < 37
      pr_ids = []
      Rails.logger.debug "Importing prosumers"
      dbconn = ActiveRecord::Base.connection_pool.checkout
      Upsert.batch(dbconn, :prosumers) do |upsert|
        CSV.foreach "test/fixtures/prosumers.sql", col_sep: "\t" do |row|
          upsert.row({
                         id: row[0].to_i
                     }, {
                         edms_id: row[0].to_i + 100000,
                         name: row[1],
                         location: row[2].to_f,
                         created_at: row[3].to_datetime,
                         updated_at: row[4].to_datetime,
                         cluster_id: row[5].to_i,
                         building_type_id: row[7].to_i,
                         connection_type_id: row[8].to_i,
                         location_x: row[9].to_f,
                         location_y: row[10].to_f,
                         prosumer_category_id: prosumer_categories(:one).id
                     })
          pr_ids.push row[0].to_i
        end
      end
      @prosumers = Prosumer.where(id: pr_ids)
      ActiveRecord::Base.connection_pool.checkin(dbconn)
    end

    if DataPoint.where(prosumer: @prosumers).count < 100
      Rails.logger.debug "Importing datapoints"
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      raw.copy_data "COPY data_points (id, prosumer_id, interval_id, "\
                    "timestamp, production, consumption, storage, f_timestamp, "\
                    "f_production, f_consumption, f_storage, dr, reliability, "\
                    "created_at, updated_at) FROM stdin;" do

        c = 0
        File.open("test/fixtures/data_points.sql", 'r').each do |line|
          c = c + 1
          raw.put_copy_data line if c > 1
        end
        # raw.put_copy_data File.read("../prosumers.sql")
      end
      ActiveRecord::Base.connection_pool.checkin(dbconn)
      Rails.logger.debug "We have #{DataPoint.count} data points"
    end

    @startdate = '2015/3/23'.to_datetime
    @trainend = '2015/3/30'.to_datetime
    @enddate = '25/5/2015'.to_datetime
    #@enddate = '27/4/2015'.to_datetime



    max = (@startdate .. @trainend).count * 24
    Rails.logger.debug "max = #{max}"
    @prosumers = @prosumers.reject do |p|
#       Rails.logger.debug p.data_points.where(interval: 2, timestamp: startdate .. enddate).count
      p.data_points
          .where(interval: 2, timestamp: @startdate .. @trainend)
          .where("consumption > ?", 0)
          .count < max / 2 ||
          p.data_points
              .where(interval: 2, timestamp: @startdate .. @trainend)
              .max{|dp| dp.consumption} == 0
    end
    # ActiveRecord::Base.connection.execute(IO.read("../prosumers_and_data_points.sql"))
    Rails.logger.debug "data imported, #{@prosumers.count} prosumers with valid training data"
  end
end

class ActiveSupport::TestCaseWithProsumptionData < ActiveSupport::TestCase
  include ProsumptionData

  setup do
    load_prosumption_data
  end

end

class ActionController::TestCaseWithProsumptionData < ActionController::TestCase
  include ProsumptionData

  setup do
    load_prosumption_data
  end

end

class ActionDispatch::IntegrationTestWithProsumptionData < ActionDispatch::IntegrationTest
  include ProsumptionData

  setup do
    load_prosumption_data
  end

end

class ActiveJob::TestCaseWithProsumptionData < ActiveJob::TestCase
  include ProsumptionData

  setup do
    load_prosumption_data
  end

end
