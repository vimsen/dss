class CreateEnergyPrices < ActiveRecord::Migration
  def change
    create_table :energy_prices do |t|
      t.datetime :date
      t.integer :dayhour
      t.float :price

      t.timestamps
    end
  end
end
