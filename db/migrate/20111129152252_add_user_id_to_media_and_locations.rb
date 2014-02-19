class AddUserIdToMediaAndLocations < ActiveRecord::Migration
  def self.up
    admin = User.find_by_login "admin"

    add_column :locations, :user_id, :integer, :default => (admin.nil? ? 1 : admin.id)
    add_column :media, :user_id, :integer, :default => (admin.nil? ? 1 : admin.id)
    add_index :locations, :user_id
    add_index :media, :user_id
  end

  def self.down
    remove_column :locations, :user_id
    remove_column :media, :user_id
  end
end
