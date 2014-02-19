class AddUserIdToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :user_id, :integer

    admin = User.find_by_login "admin"
    Tour.all.each{|t| t.update_attribute(:user_id, admin.id) } if admin
  end

  def self.down
    remove_column :tours, :user_id
  end
end
