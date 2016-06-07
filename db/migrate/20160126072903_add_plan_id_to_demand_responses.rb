class AddPlanIdToDemandResponses < ActiveRecord::Migration
  def change
    add_column :demand_responses, :plan_id, :integer
  end
end
