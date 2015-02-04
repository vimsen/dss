class CreateClusterings < ActiveRecord::Migration
  def change
    create_table :clusterings do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
