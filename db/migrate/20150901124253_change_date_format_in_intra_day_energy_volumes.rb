class ChangeDateFormatInIntraDayEnergyVolumes < ActiveRecord::Migration
  def up
    change_column :intra_day_energy_volumes, :date, :date
  end

  def down
    change_column :intra_day_energy_volumes, :date, :datetime
  end
end
