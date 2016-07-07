#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("oikiakoi.csv", col_sep: ";", headers: true, encoding: "ISO8859-7")

time = DateTime.parse("2015-01-01T00:15:00+02:00")

prosumers = {}
CSV.open("oikiakoi.sql", "wb", col_sep: "\t") do |csv_out|
  csv1.each_with_index do |row, linenum|
    has_non_zero = false
    new_rows = []
    row.each_with_index do |value, column|
      id = column + 10000
      if linenum == 0
        prosumers[id] = value[1].encode('utf-8') if column > 0
      else
        new_rows << [id, 1, time, value[1].sub(',', '.').to_f] if column > 0
        has_non_zero = true if value[1].sub(',', '.').to_f > 0 && column > 0
      end
    end
    if linenum > 0
      if has_non_zero
        new_rows.each {|r| csv_out << r}
        time += 15.minutes
      end
    end
  end
end

CSV.open("prosumers_oikiakoi.sql", "wb", col_sep: "\t") do |csv_out|
  prosumers.each do |id, location|
    csv_out << [id, id + 100000, "oikiakoi_#{id}", location]
  end
end
