#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

prosumers = {}

# id = 11000

csv_in = CSV.open("photovoltaika_MV.csv", col_sep: "\t", headers: false)
CSV.open("photovoltaika_MV.sql", "wb", col_sep: "\t") do |csv_out|
  csv_in.each do |row|
    row_array = row.to_a
    location = row_array.shift
    id = 11000 + row_array.shift.to_i
#     row_array.shift
    row_array.shift # Remove "active-" column
    date = Date.parse(row_array.shift)
    # id += 1 if date == '2015/01/01'.to_date
    prosumers[id] = location
    row_array.slice!(12..15) if ['2015/03/29'.to_date, '2016/03/27'.to_date ].include? date
    row_array.each_with_index do |value, column|
      time = date + ((column + 1) * 15).minutes
      csv_out << [id, 1, time.to_datetime.new_offset(2.0/24).to_s, value.gsub(/,/, "")] unless value.nil?
      # puts "#{id}\t1\t#{time.to_datetime.to_s}\t#{value}\t#{location}" unless value.nil?
    end
  end
end

=begin
CSV.open("prosumers_photovoltaika_MV.sql", "wb", col_sep: "\t") do |csv_out|
  prosumers.each do |id, location|
    csv_out << [id, id + 100000, "photovoltaika_MV_#{id}", location]
  end
end
=end

