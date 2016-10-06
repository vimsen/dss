class AddProsumerIdIndexToDataPoints < ActiveRecord::Migration
  def change
    add_index :data_points, :prosumer_id
  end
end
