class AddForecastTypeToForecasts < ActiveRecord::Migration
  def change
    add_column :forecasts, :forecast_type, :integer
  end
end
