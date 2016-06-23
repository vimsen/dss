#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("pv_lv_hedno.csv", headers: true)

time = DateTime.parse("2015-01-01T00:15:00+02:00")

prosumers = {}
CSV.open("pv_lv_hedno.sql", "wb", col_sep: "\t") do |csv_out|
  csv1.each do |row|
  # time = Time.parse(row[0]).to_datetime.in_time_zone("UTC").to_s
  # time -= time.utc_offset
    row.each_with_index do |value, column|
      id = column+1000
      csv_out << [id, 1, time, value[1]] if column > 0
      # puts "#{id}\t1\t#{time}\t#{value[1]}" if column > 0
      prosumers[id] = 'Υ/Σ Λητής, Θεσσαλονίκη'
    end
    time += 15.minutes
  end
end

CSV.open("prosumers_pv_lv_hedno.sql", "wb", col_sep: "\t") do |csv_out|
  prosumers.each do |id, location|
    csv_out << [id, id + 100000, "pv_lv_#{id}", location]
  end
end
