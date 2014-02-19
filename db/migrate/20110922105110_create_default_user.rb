class CreateDefaultUser < ActiveRecord::Migration
  def self.up
    User.reset_column_information
    User.create!(:login => 'admin', :password => '123456')
  end

  def self.down
    User.delete_all
  end
end
