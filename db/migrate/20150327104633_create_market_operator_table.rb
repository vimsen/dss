class CreateMarketOperatorTable < ActiveRecord::Migration

  def change
    create_table :market_operators do |t|

	t.string :name
        t.text :description
	t.timestamps

    end
  end


end
