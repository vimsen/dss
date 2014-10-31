class CreateProsumersUsers < ActiveRecord::Migration
  def self.up
    create_table :prosumers_users, id: false do |t|
      t.integer :prosumer_id
      t.integer :user_id
    end
    
    add_index :prosumers_users, [:prosumer_id, :user_id]
  end
  
  def self.down
    drop_table :prosumers_users
  end
end
