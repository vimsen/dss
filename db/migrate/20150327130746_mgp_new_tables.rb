class MgpNewTables < ActiveRecord::Migration
  def change

     create_table :day_ahead_energy_demands do |t|
              t.datetime :date
              t.integer :dayhour
              t.float :demand
              t.integer :region_id
              t.timestamps
     end

     create_table :day_ahead_energy_volumes do |t|
              t.datetime :date
              t.integer :dayhour
              t.float :purchases
	      t.float :sales
              t.integer :region_id
              t.timestamps
     end

  end
end
