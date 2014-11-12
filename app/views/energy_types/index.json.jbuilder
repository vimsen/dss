json.array!(@energy_types) do |energy_type|
  json.extract! energy_type, :id, :name
  json.url energy_type_url(energy_type, format: :json)
end
