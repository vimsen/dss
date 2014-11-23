class AddBuildingTypeToProsumers < ActiveRecord::Migration
  def change
    add_reference :prosumers, :building_type, index: true
  end
end
