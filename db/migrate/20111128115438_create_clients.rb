class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      t.string :email
      t.string :name
      t.integer :market_client_id
      t.string :password
      t.string :api_key

      t.integer :user_id
    end

    add_index :clients, :api_key
    add_index :clients, :user_id
  end

  def self.down
    drop_table :clients
  end
end
