#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("aiolika_MV.csv", col_sep: "\t", headers: false)

time = DateTime.parse("2015-01-01T00:00:00+02:00")

csv1.each do |row|
# time = Time.parse(row[0]).to_datetime.in_time_zone("UTC").to_s
# time -= time.utc_offset
  # puts "#{row}"
  row_array = row.to_a
  # puts "#{row}"
  location = row_array.shift
  id = 2000 + row_array.shift.to_i
  date = Date.parse(row_array.shift)

  row_array.slice!(12..15) if date == '2015/03/29'.to_date

  row_array.each_with_index do |value, column|
    time = date + (column * 15).minutes
    puts "#{id}\t#{time}\t1\t#{location}\t#{value}" unless value.nil?
  end
end



