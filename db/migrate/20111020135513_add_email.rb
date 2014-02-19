class AddEmail < ActiveRecord::Migration
  def self.up
    User.first.update_attribute(:email, Rails.env.production? ? 'waldmanjulie@gmail.com' : 'aminiailo@cogniance.com')
  end

  def self.down
  end
end
