json.array!(@prosumer_categories) do |prosumer_category|
  json.extract! prosumer_category, :id, :name, :description, :real_time
  json.url prosumer_category_url(prosumer_category, format: :json)
end
