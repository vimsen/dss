#!/usr/bin/env ruby

require 'csv'
require 'time'
require 'active_support/all'

csv1 = CSV.open("epaggelmatikoi.csv", col_sep: ";", headers: true, encoding: "ISO8859-7")

time = DateTime.parse("2015-01-01T00:15:00+02:00")

prosumers = {}
CSV.open("epaggelmatikoi.sql", "wb", col_sep: "\t") do |csv_out|
  csv1.each_with_index do |row, linenum|
    has_non_zero = false
    new_rows = []
    row.each_with_index do |value, column|
      id = column + 8000
      if linenum == 0
        prosumers[id] = value[1].encode('utf-8') if column > 0
      else
        newval = value[1].sub(',', '.')
        new_rows << [id, 1, time, newval.to_f] if column > 0 && (Float(newval) rescue false)
        has_non_zero = true if newval.to_f > 0 && column > 0
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
=begin

CSV.open("prosumers_epaggelmatikoi.sql", "wb", col_sep: "\t") do |csv_out|
  prosumers.each do |id, location|
    csv_out << [id, id + 100000, "epaggelmatikoi_#{id}", location]
  end
end
=end
