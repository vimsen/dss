class AddIndexToDataPoints < ActiveRecord::Migration
  def change
    add_index :data_points, [:timestamp, :prosumer_id, :interval_id], :unique => true
  end
end
