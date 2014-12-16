class CreateLogInstances < ActiveRecord::Migration
  def change
    create_table :log_instances do |t|
   	t.integer :instance_id
        t.integer :status
        t.timestamps
    end
  end
end
