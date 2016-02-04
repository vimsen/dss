json.array!(@dr_targets) do |dr_target|
  json.extract! dr_target, :id, :volume, :timestamp, :demand_response_id
  json.url dr_target_url(dr_target, format: :json)
end
