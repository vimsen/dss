json.array!(@dr_planneds) do |dr_planned|
  json.extract! dr_planned, :id, :prosumer_id, :volume, :timestamp, :demand_response_id
  json.url dr_planned_url(dr_planned, format: :json)
end
