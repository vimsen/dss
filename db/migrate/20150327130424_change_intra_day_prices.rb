class ChangeIntraDayPrices < ActiveRecord::Migration
  def change
	    rename_column :intra_day_energy_prices, :market_id, :region_id
  end
end
