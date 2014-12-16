class AlterInstancesTable < ActiveRecord::Migration
  def change
	remove_column :instances, :market_id
	add_column :instances, :total_execution_time, :integer

  end
end
