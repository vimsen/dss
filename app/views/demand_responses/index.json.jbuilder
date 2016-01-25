json.array!(@demand_responses) do |demand_response|
  json.extract! demand_response, :id, :interval_id
  json.url demand_response_url(demand_response, format: :json)
end
