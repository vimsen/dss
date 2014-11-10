json.array!(@day_aheads) do |day_ahead|
  json.extract! day_ahead, :id, :prosumer_id, :date
  json.url day_ahead_url(day_ahead, format: :json)
end
