class CreateMarketRegions < ActiveRecord::Migration
  def change
    create_table :market_regions do |t|
	   t.integer :mo_id
	   t.string :name
           t.timestamp
    end
  end
end
