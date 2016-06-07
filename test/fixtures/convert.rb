#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("pv_lv_hedno.csv", headers: true)

time = DateTime.parse("2015-01-01T00:00:00+02:00")

csv1.each do |row|
# time = Time.parse(row[0]).to_datetime.in_time_zone("UTC").to_s
# time -= time.utc_offset
  row.each_with_index do |value, column|
    puts "#{column}\t1\t#{time}\t#{value[1]}" if column > 0
  end
  time += 15.minutes
end



