class ChangeDateFormatInMbProvisionalTotalData < ActiveRecord::Migration
  def up
    change_column :mb_provisional_total_data, :date, :date
  end

  def down
    change_column :mb_provisional_total_data, :date, :datetime
  end
end
