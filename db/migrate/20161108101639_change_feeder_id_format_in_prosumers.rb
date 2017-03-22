class ChangeFeederIdFormatInProsumers < ActiveRecord::Migration
  def up
    change_column :prosumers, :feeder_id, :string
  end

  def down
    change_column :prosumers, :feeder_id, "integer USING CAST(feeder_id AS integer)"
  end
end
