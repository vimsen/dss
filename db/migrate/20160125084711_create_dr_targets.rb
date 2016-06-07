class CreateDrTargets < ActiveRecord::Migration
  def change
    create_table :dr_targets do |t|
      t.float :volume
      t.datetime :timestamp
      t.references :demand_response, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
