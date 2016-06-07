class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.references :user, index: true, foreign_key: true
      t.string :name
      t.integer :algorithm_id
      t.text :params
    end
  end
end
