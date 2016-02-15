class AddIndexToSlaItems < ActiveRecord::Migration
  def change
    add_index :sla_items, [:timestamp, :interval_id, :bid_id], unique: true
  end
end
