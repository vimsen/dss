#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("biomhxanikoi.csv", col_sep: ";", headers: true)

time = DateTime.parse("2015-01-01T00:00:00+02:00")

prosumers = {}
CSV.open("biomhxanikoi.sql", "wb", col_sep: "\t") do |csv_out|
  csv1.each_with_index do |row, linenum|
    row.each_with_index do |value, column|
      id = column + 6000
      if linenum == 0
        prosumers[id] = value[1] if column > 0
      else
        csv_out << [id, 1, time, value[1].sub!(',', '.').to_f] if column > 0
      end
    end
    time += 15.minutes
  end
end

CSV.open("prosumers_biomhxanikoi.sql", "wb", col_sep: "\t") do |csv_out|
  prosumers.each do |id, location|
    csv_out << [id, id + 100000, "biomhxanikoi_#{id}", location]
  end
end
