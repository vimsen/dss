module HednoData
  def load_prosumption_data
    Rails.logger.debug "Importing HEDNO LV PV prosumers"

    # if DataPoint.where(prosumer_id: 1001..2050).count == 0

    if Prosumer.where(id: 3001..12050).count == 0

=begin
      Prosumer.create(1001.upto(1040).map do |i|
        {id: i, name: "pr #{i}", edms_id: i+100000}
      end)

      Prosumer.create( CSV.open("test/fixtures/prosumers_aiolika_MV.sql", col_sep: "\t", headers: false).map do |row|
        {id: row[0].to_i, name: "wind_#{row[0]}", edms_id: row[0].to_i+100000, location: row[1]}
      end)
=end

      # Prosumer.connection.commit_db_transaction

      # Rails.logger.debug "Prosumer ids: #{@prosumers.map{|p| p.name}}"


      Rails.logger.debug "Importing datapoints"
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      raw.copy_data "COPY prosumers (id, edms_id, name, location) FROM stdin;" do
        File.open("test/fixtures/prosumers_pv_lv_hedno.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_aiolika_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_emporikoi_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_biomhxanikoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_biomhxanikoi_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_epaggelmatikoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_fwtismos_odwn_plateiwn.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_oikiakoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        File.open("test/fixtures/prosumers_photovoltaika_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
      end


      Rails.logger.debug "Prosumer ids3: #{Prosumer.all.map{|p| p.name}}"

      raw.copy_data "COPY data_points (prosumer_id, interval_id, "\
                  "timestamp, production) FROM stdin;" do
        Rails.logger.debug "#{DateTime.now}: Loading pv_lv_hedno.sql"
        File.open("test/fixtures/pv_lv_hedno.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading aiolika_MV.sql"
        File.open("test/fixtures/aiolika_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading photovoltaika_MV.sql"
        File.open("test/fixtures/photovoltaika_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
      end

      raw.copy_data "COPY data_points (prosumer_id, interval_id, "\
                  "timestamp, consumption) FROM stdin;" do
        Rails.logger.debug "#{DateTime.now}: Loading emporikoi_MV.sql"
        File.open("test/fixtures/emporikoi_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading biomhxanikoi.sql"
        File.open("test/fixtures/biomhxanikoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading biomhxanikoi_MV.sql"
        File.open("test/fixtures/biomhxanikoi_MV.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading epaggelmatikoi.sql"
        File.open("test/fixtures/epaggelmatikoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading fwtismos_odwn_plateiwn.sql"
        File.open("test/fixtures/fwtismos_odwn_plateiwn.sql", 'r').each do |line|
          raw.put_copy_data line
        end
        Rails.logger.debug "#{DateTime.now}: Loading oikiakoi.sql"
        File.open("test/fixtures/oikiakoi.sql", 'r').each do |line|
          raw.put_copy_data line
        end
      end
      Rails.logger.debug "#{DateTime.now}: Done Loading data"
      ActiveRecord::Base.connection_pool.checkin(dbconn)
      Rails.logger.debug "We have #{DataPoint.count} data points"

    end
    @prosumers = Prosumer.where(id: 3001..12050)
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
