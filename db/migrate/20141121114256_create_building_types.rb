class CreateBuildingTypes < ActiveRecord::Migration
  def change
    create_table :building_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
