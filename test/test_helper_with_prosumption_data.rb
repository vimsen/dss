class ActiveSupport::TestCaseWithProsumptionData < ActiveSupport::TestCase

  setup do
    puts "Importing data"

    if Prosumer.count < 37
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      raw.copy_data "COPY prosumers (id, name, location, created_at, updated_at, cluster_id, intelen_id, building_type_id, connection_type_id, location_x, location_y) FROM stdin WITH (FORMAT 'csv', DELIMITER E'\t', NULL \"\N\")" do
        c = 0
        File.open("test/fixtures/prosumers.sql", 'r').each do |line|
           c = c + 1
          raw.put_copy_data line if c > 1
        end
        # raw.put_copy_data File.read("../prosumers.sql")
      end
      ActiveRecord::Base.connection_pool.checkin(dbconn)
      puts "We have #{Prosumer.count} prosumers"

    end
    @prosumers = Prosumer.where(intelen_id: 1..37)


    if DataPoint.count < 10
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      raw.copy_data "COPY data_points (id, prosumer_id, interval_id, timestamp, production, consumption, storage, f_timestamp, f_production, f_consumption, f_storage, dr, reliability, created_at, updated_at) FROM stdin;" do
        c = 0
        File.open("test/fixtures/data_points.sql", 'r').each do |line|
           c = c + 1
          raw.put_copy_data line if c > 1
        end
        # raw.put_copy_data File.read("../prosumers.sql")
      end
      ActiveRecord::Base.connection_pool.checkin(dbconn)
      puts "We have #{DataPoint.count} data points"
    end

    # ActiveRecord::Base.connection.execute(IO.read("../prosumers_and_data_points.sql"))
    puts "data imported"
  end

end
