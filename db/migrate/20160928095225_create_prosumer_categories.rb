class CreateProsumerCategories < ActiveRecord::Migration
  def change
    create_table :prosumer_categories do |t|
      t.string :name
      t.text :description
      t.boolean :real_time

      t.timestamps null: false
    end
  end
end
