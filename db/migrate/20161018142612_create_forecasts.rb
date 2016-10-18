class CreateForecasts < ActiveRecord::Migration
  def change
    create_table :forecasts do |t|
      t.references :prosumer, index: true, foreign_key: true
      t.references :interval, index: true, foreign_key: true
      t.datetime :timestamp
      t.datetime :forecast_time
      t.float :production
      t.float :consumption
      t.float :storage

      t.timestamps null: false
    end
    add_index :forecasts, [:timestamp, :prosumer_id, :interval_id, :forecast_time], :unique => true
  end
end
