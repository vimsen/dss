class DropTableEnergyMarkets < ActiveRecord::Migration
  def change
	drop_table :energy_markets
  end
end
