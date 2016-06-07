class AddIndexToDrActuals < ActiveRecord::Migration
  def change
    add_index :dr_actuals, [:prosumer_id, :timestamp, :demand_response_id], unique: true, name: "pros_time_dr_index"
  end
end
