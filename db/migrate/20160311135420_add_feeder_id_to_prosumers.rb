class AddFeederIdToProsumers < ActiveRecord::Migration
  def change
    add_column :prosumers, :feeder_id, :integer
  end
end
