class CreateEnergyTypes < ActiveRecord::Migration
  def change
    create_table :energy_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
