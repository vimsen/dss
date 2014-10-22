class AddClusterIdToProsumer < ActiveRecord::Migration
  def change
    add_column :prosumers, :cluster_id, :integer
  end
end
