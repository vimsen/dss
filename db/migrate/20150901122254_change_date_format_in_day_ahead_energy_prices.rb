class ChangeDateFormatInDayAheadEnergyPrices < ActiveRecord::Migration
  def up
    change_column :day_ahead_energy_prices, :date, :date
  end

  def down
    change_column :day_ahead_energy_prices, :date, :datetime
  end
end
