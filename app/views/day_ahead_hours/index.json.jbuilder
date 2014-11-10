json.array!(@day_ahead_hours) do |day_ahead_hour|
  json.extract! day_ahead_hour, :id, :day_ahead_id, :time, :production, :consumption
  json.url day_ahead_hour_url(day_ahead_hour, format: :json)
end
