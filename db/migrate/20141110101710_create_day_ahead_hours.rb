class CreateDayAheadHours < ActiveRecord::Migration
  def change
    create_table :day_ahead_hours do |t|
      t.references :day_ahead, index: true
      t.integer :time
      t.float :production
      t.float :consumption

      t.timestamps
    end
  end
end
