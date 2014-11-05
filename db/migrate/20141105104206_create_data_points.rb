class CreateDataPoints < ActiveRecord::Migration
  def change
    create_table :data_points do |t|
      t.integer :prosumer_id
      t.integer :interval_id
      t.datetime :timestamp
      t.float :production
      t.float :consumption
      t.float :storage
      t.datetime :f_timestamp
      t.float :f_production
      t.float :f_consumption
      t.float :f_storage
      t.float :dr
      t.float :reliability

      t.timestamps
    end
  end
end
