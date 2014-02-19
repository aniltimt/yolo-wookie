class AddStreetAndBuildingToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :street, :string
    add_column :locations, :building, :string
  end

  def self.down
    remove_column :locations, :street
    remove_column :locations, :building
  end
end
