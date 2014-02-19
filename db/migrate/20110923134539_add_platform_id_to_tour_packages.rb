class AddPlatformIdToTourPackages < ActiveRecord::Migration
  def self.up
    add_column :tour_packages, :platform_id, :integer, :default => 1, :null => false
    add_index :tour_packages, :platform_id
  end

  def self.down
    remove_column :tour_packages, :platform_id
  end
end
