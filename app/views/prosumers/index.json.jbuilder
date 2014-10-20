json.array!(@prosumers) do |prosumer|
  json.extract! prosumer, :id, :name, :location
  json.url prosumer_url(prosumer, format: :json)
end
