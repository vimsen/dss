json.array!(@data_points) do |data_point|
  json.extract! data_point, :id, :prosumer_id, :interval_id, :timestamp, :production, :consumption, :storage, :f_timestamp, :f_production, :f_consumption, :f_storage, :dr, :reliability
  json.url data_point_url(data_point, format: :json)
end
