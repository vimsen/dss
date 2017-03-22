json.array!(@prosumers) do |prosumer|
  json.extract! prosumer, :id, :name, :location, :edms_id
  json.url prosumer_url(prosumer, format: :json)
end
