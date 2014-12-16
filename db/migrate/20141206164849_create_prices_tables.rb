class CreatePricesTables < ActiveRecord::Migration

    def change
	
 	drop_table :energy_prices

	create_table :energy_markets do |t|
	      t.string :name
	      t.timestamps
	end

	create_table :day_ahead_energy_prices do |t|
	      t.datetime :date
	      t.integer :dayhour
	      t.float :price
	      t.integer :market_id
	      t.timestamps
	end

	create_table :intra_day_energy_prices do |t|
              t.datetime :date
              t.integer :dayhour
              t.float :price
	      t.integer :interval_id
              t.integer :market_id
              t.timestamps
        end


  end
end
