class AddIntelenIdToProsumers < ActiveRecord::Migration
  def change
    add_column :prosumers, :intelen_id, :integer
    add_index :prosumers, :intelen_id, :unique => true
  end
end
