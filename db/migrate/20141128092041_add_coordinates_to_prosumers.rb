class AddCoordinatesToProsumers < ActiveRecord::Migration
  def change
    add_column :prosumers, :location_x, :float
    add_column :prosumers, :location_y, :float
  end
end
