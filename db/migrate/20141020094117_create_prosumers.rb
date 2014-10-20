class CreateProsumers < ActiveRecord::Migration
  def change
    create_table :prosumers do |t|
      t.string :name
      t.string :location

      t.timestamps
    end
  end
end
