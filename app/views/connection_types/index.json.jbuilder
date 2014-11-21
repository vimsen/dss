json.array!(@connection_types) do |connection_type|
  json.extract! connection_type, :id, :name
  json.url connection_type_url(connection_type, format: :json)
end
