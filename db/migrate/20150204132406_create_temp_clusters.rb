class CreateTempClusters < ActiveRecord::Migration
  def change
    create_table :temp_clusters do |t|
      t.string :name
      t.text :description
      t.references :clustering, index: true

      t.timestamps
    end
  end
end
