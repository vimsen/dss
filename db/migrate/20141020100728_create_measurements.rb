class CreateMeasurements < ActiveRecord::Migration
  def change
    create_table :measurements do |t|
      t.datetime :timeslot
      t.float :power
      t.integer :prosumer_id

      t.timestamps
    end
  end
end
