class ChangeFeederIdFormatInDemandResponses < ActiveRecord::Migration
  def up
    change_column :demand_responses, :feeder_id, :string
  end

  def down
    change_column :demand_responses, :feeder_id, "integer USING CAST(feeder_id AS integer)"
  end
end
