class CreateBids < ActiveRecord::Migration
  def change
    create_table :bids do |t|
      t.date :date
      t.integer :mo_id

      t.timestamps null: false
    end
  end
end
