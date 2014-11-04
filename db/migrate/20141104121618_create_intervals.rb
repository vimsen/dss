class CreateIntervals < ActiveRecord::Migration
  def change
    create_table :intervals do |t|
      t.integer :duration
      t.string :name

      t.timestamps
    end
  end
end
