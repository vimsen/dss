class ChangeIntraDayPrices < ActiveRecord::Migration
  def change
	    rename_column :day_ahead_energy_prices, :market_id, :region_id
  end
end
