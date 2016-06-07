class AddDatesToConfigurations < ActiveRecord::Migration
  def change
    add_column :configurations, :created_at, :datetime
    add_column :configurations, :updated_at, :datetime
  end
end
