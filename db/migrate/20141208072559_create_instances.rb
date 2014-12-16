class CreateInstances < ActiveRecord::Migration
  def change
    create_table :instances do |t|
 	t.integer :user_id
        t.integer :configuration_id
        t.string  :results
	t.string  :status
        t.string  :reason
        t.string  :instance_name
        t.string  :worker
        t.integer :market_id
        t.timestamps
    end
  end
end
