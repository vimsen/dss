json.array!(@clusters) do |cluster|
  json.extract! cluster, :id, :name, :description
  json.url cluster_url(cluster, format: :json)
end
