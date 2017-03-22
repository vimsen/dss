json.array!(@forecasts) do |forecast|
  json.extract! forecast, :id, :prosumer_id, :interval_id, :timestamp, :forecast_time, :production, :consumption, :storage
  json.url forecast_url(forecast, format: :json)
end
