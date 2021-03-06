require 'upsert'
require 'csv'

table_names = [ 
  AncillaryServicesData,
  DayAheadEnergyDemand,
  DayAheadEnergyPrice,
  DayAheadEnergyVolume,
  EnergyEfficiencyCertificate,
  GreenCertificate,
  IntraDayEnergyPrice,
  IntraDayEnergyVolume,
  MbProvisionalTotalData,
]

# Parallel.each(table_names, in_threads: 30) do |tbl_name|

table_names.each do |tbl_name|


  puts "#{tbl_name} started"
  headers = nil
  rows = []
  lastid = nil

  CSV.foreach "db/initdata/#{tbl_name}.csv", headers: true do |row|
    headers ||= row.headers
    unless row["id"].nil?
      rows << row
      lastid = row["id"].to_i
    end
  end

  puts "#{tbl_name} read, #{rows.length}"

  CSV.open "db/initdata/#{tbl_name}.csv", 'a', write_headers: false, headers: headers do |csv|
    rows.each do |row|

      lastid += 1
      row["id"] = lastid
      row["date"] = (row["date"].to_date + 1.year).to_s
      #puts "id: #{row["id"]}"
      #puts "date: #{row["date"]}"
      csv << row unless tbl_name == DayAheadEnergyPrice && row["region_id"] == '1'
    end
  end
  puts "#{tbl_name} written"



end

