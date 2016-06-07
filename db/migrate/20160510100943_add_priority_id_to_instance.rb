class AddPriorityIdToInstance < ActiveRecord::Migration
  def change
     add_column :instances, :priority_id, :integer, :default => 1
  end
end
