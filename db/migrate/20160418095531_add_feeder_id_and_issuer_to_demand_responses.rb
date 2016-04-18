class AddFeederIdAndIssuerToDemandResponses < ActiveRecord::Migration
  def change
    add_column :demand_responses, :feeder_id, :integer
    add_column :demand_responses, :issuer, :string
  end
end
