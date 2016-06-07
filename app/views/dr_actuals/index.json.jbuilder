json.array!(@dr_actuals) do |dr_actual|
  json.extract! dr_actual, :id, :prosumer_id, :volume, :timestamp, :demand_response_id
  json.url dr_actual_url(dr_actual, format: :json)
end
