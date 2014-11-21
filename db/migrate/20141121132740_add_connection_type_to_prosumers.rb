class AddConnectionTypeToProsumers < ActiveRecord::Migration
  def change
    add_reference :prosumers, :connection_type, index: true
  end
end
