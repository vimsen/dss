class VariousMarketTables < ActiveRecord::Migration
  def change


    create_table :intra_day_energy_volumes do |t|
              t.datetime :date
              t.integer :dayhour
              t.float :purchases
              t.float :sales
              t.integer :region_id
              t.integer :interval_id
              t.timestamps
     end

     create_table :ancillary_services_data do |t|
              t.datetime :date
              t.integer :dayhour
	      t.float :purchased_volumes
              t.float :sold_volumes
	      t.float :min_purchasing_price
	      t.float :average_purchasing_price
              t.float :max_selling_price
              t.float :average_selling_price
              t.integer :region_id
              t.timestamps
     end

     create_table :mb_provisional_total_data do |t|
              t.datetime :date
              t.integer :dayhour
              t.float :purchased_revoked
              t.float :purchased_not_revoked
              t.float :sold_revoked
              t.float :sold_not_revoked
              t.integer :region_id
              t.timestamps
     end


   create_table :energy_efficiency_certificates do |t|
              t.datetime :date
              t.string :type
              t.float :price_reference
              t.float :price_cumulative_average
              t.float :price_minimum
              t.float :price_maximum
              t.float :tee_traded
              t.timestamps
     end

     create_table :green_certificates do |t|
              t.datetime :date
              t.string :certificate_type
	      t.string :reference_year
              t.float :traded_volumes
              t.float :price_reference
              t.float :price_minimum
              t.float :price_maximum
              t.timestamps
     end

  end
end
