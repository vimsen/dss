class CreateProsumersTempClusters < ActiveRecord::Migration
  def change
    create_table :prosumers_temp_clusters do |t|
      t.integer "prosumer_id"
      t.integer "temp_cluster_id"
    end

    add_index "prosumers_temp_clusters", ["prosumer_id", "temp_cluster_id"], name: "index_prosumers_temp_clusters_on_prosumer_id_and_temp_cluster", using: :btree
  end
end
