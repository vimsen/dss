json.array!(@users) do |user|
  json.extract! user, :id, :email, :roles, :prosumers
  json.url user_url(user, format: :json)
end
