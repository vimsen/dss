class CreateDemandResponses < ActiveRecord::Migration
  def change
    create_table :demand_responses do |t|
      t.references :interval, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
