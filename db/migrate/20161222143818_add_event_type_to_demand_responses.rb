class AddEventTypeToDemandResponses < ActiveRecord::Migration
  def change
    add_column :demand_responses, :event_type, :integer
  end
end
