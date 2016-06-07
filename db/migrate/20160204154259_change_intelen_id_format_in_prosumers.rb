class ChangeIntelenIdFormatInProsumers < ActiveRecord::Migration
  def up
    change_column :prosumers, :intelen_id, :string
  end

  def down
    change_column :prosumers, :intelen_id, :integer
  end
end
