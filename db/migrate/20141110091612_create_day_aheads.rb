class CreateDayAheads < ActiveRecord::Migration
  def change
    create_table :day_aheads do |t|
      t.references :prosumer, index: true
      t.date :date

      t.timestamps
    end
  end
end
