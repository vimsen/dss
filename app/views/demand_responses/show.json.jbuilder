json.extract! @demand_response, :id, :interval_id
json.dr_targets @demand_response.dr_targets do |dr_target|
  json.id dr_target.id
  json.volume dr_target.volume
  json.timestamp dr_target.timestamp
end
json.extract! @demand_response, :created_at, :updated_at
