json.array!(@intervals) do |interval|
  json.extract! interval, :id, :duration, :name
  json.url interval_url(interval, format: :json)
end
