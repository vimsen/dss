json.array!(@sla_items) do |sla_item|
  json.extract! sla_item, :id, :bid_id, :timestamp, :interval_id, :volume, :price
  json.url sla_item_url(sla_item, format: :json)
end
