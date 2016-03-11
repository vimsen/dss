class ChangeColumnName < ActiveRecord::Migration
  def change
    rename_column :prosumers, :intelen_id, :edms_id
  end
end
