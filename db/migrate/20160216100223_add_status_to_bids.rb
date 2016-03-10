class AddStatusToBids < ActiveRecord::Migration
  def change
    add_column :bids, :status, :integer
    add_index :bids, :status
  end
end
