class AddProsumerCategoryToDemandResponses < ActiveRecord::Migration
  def change
    add_reference :demand_responses, :prosumer_category, index: true, foreign_key: true
  end
end
