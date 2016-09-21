require 'upsert'
require 'csv'

table_names = Dir["db/initdata/*.csv"].map{|p| File.basename p, ".csv"}

puts JSON.pretty_generate table_names
# table_names = ["Prosumer", "User", "User::HABTM_Prosumers"]

ActiveRecord::Base.connection.disable_referential_integrity do
  # Parallel.each(table_names, in_threads: 30) do |tbl_name|

  table_names.each do |tbl_name|
    puts "#{tbl_name}.create"

    dbconn = ActiveRecord::Base.connection_pool.checkout
    raw  = dbconn.raw_connection

    csv = File.open("db/initdata/#{tbl_name}.csv")
    head = csv.first

    begin
      raw.copy_data "COPY #{tbl_name.constantize.table_name} (#{head}) FROM stdin DELIMITER ',' CSV;" do
        csv.each_with_index { |row, i| raw.put_copy_data(row) }
      end
    rescue Exception => e
      puts "Error during processing: #{$!}"
      puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
    ensure
      csv.close
      dbconn.close

    end

=begin


    status = Upsert.batch(tbl_name.constantize.connection, tbl_name.constantize.table_name) do |upsert|
      CSV.foreach "db/initdata/#{tbl_name}.csv", headers: true do |row|
#      puts "#{tbl_name}: #{row['id']}"
        if row.key? 'id'
          upsert.row({id: row['id']}, row.to_h)
        else
          upsert.row row.to_h
        end
      end
    end
=end
    puts "#{tbl_name}: inserted"
  end
end

