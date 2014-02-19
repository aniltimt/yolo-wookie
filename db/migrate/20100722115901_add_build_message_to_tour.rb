class AddBuildMessageToTour < ActiveRecord::Migration
  def self.up
    add_column :tours, :build_message, :string
  end

  def self.down
    remove_column :tours, :build_message
  end
end
