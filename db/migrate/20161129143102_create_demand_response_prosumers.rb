class CreateDemandResponseProsumers < ActiveRecord::Migration
  def change
    create_table :demand_response_prosumers do |t|
      t.references :demand_response, index: true, foreign_key: true
      t.references :prosumer, index: true, foreign_key: true
      t.integer :drp_type

      t.timestamps null: false
    end
  end
end
