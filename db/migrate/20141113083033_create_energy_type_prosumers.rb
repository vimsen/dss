class CreateEnergyTypeProsumers < ActiveRecord::Migration
  def change
    create_table :energy_type_prosumers do |t|
      t.float :power
      t.references :energy_type, index: true
      t.references :prosumer, index: true

      t.timestamps
    end
  end
end
