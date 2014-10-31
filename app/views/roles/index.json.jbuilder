json.array!(@roles) do |role|
  json.extract! role, :id, :name, :users
  json.url role_url(role, format: :json)
end
