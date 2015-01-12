json.array!(@meters) do |meter|
  json.extract! meter, :id, :mac, :prosumer_id
  json.url meter_url(meter, format: :json)
end
