class AddProsumerCategoryToProsumers < ActiveRecord::Migration
  def change
    add_reference :prosumers, :prosumer_category, index: true, foreign_key: true
  end
end
