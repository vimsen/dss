class ChangeDateFormatInDayAheadEnergyVolumes < ActiveRecord::Migration
  def up
    change_column :day_ahead_energy_volumes, :date, :date
  end

  def down
    change_column :day_ahead_energy_volumes, :date, :datetime
  end

end
