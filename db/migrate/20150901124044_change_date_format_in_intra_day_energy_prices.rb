class ChangeDateFormatInIntraDayEnergyPrices < ActiveRecord::Migration
  def up
    change_column :intra_day_energy_prices, :date, :date
  end

  def down
    change_column :intra_day_energy_prices, :date, :datetime
  end

end
