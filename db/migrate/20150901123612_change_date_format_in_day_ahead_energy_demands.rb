class ChangeDateFormatInDayAheadEnergyDemands < ActiveRecord::Migration
  def up
    change_column :day_ahead_energy_demands, :date, :date
  end

  def down
    change_column :day_ahead_energy_demands, :date, :datetime
  end

end
