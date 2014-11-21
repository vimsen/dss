json.array!(@energy_prices) do |energy_price|
  json.extract! energy_price, :id, :date, :dayhour, :price
  json.url energy_price_url(energy_price, format: :json)
end
