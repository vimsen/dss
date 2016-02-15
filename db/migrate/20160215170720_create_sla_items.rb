class CreateSlaItems < ActiveRecord::Migration
  def change
    create_table :sla_items do |t|
      t.references :bid, index: true, foreign_key: true
      t.datetime :timestamp
      t.references :interval, index: true, foreign_key: true
      t.float :volume
      t.float :price

      t.timestamps null: false
    end
  end
end
