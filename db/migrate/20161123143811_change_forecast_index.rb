class ChangeForecastIndex < ActiveRecord::Migration
  def up
    remove_index :forecasts, name: :forecastsuniqueindex
    add_index :forecasts, [:timestamp, :prosumer_id, :interval_id, :forecast_time, :forecast_type], unique: true, name: "forecastsuniqueindex"
  end

  def down
    remove_index :forecasts, name: :forecastsuniqueindex
    add_index :forecasts, [:timestamp, :prosumer_id, :interval_id, :forecast_time], unique: true, name: "forecastsuniqueindex"
  end
end
