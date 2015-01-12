class CreateMeters < ActiveRecord::Migration
  def change
    create_table :meters do |t|
      t.string :mac
      t.references :prosumer, index: true

      t.timestamps
    end
  end
end
