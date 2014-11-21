class AddCountryEnPrice < ActiveRecord::Migration
  def change
        add_column :energy_prices, :country, :string
  end
end
