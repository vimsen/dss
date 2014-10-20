json.array!(@measurements) do |measurement|
  json.extract! measurement, :id, :timeslot, :power, :prosumer_id
  json.url measurement_url(measurement, format: :json)
end
