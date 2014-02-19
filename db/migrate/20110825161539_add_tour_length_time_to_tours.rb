class AddTourLengthTimeToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :length_in_minutes,  :integer
    add_column :tours, :length_in_km,       :integer
  end

  def self.down
    remove_column :tours, :length_in_minutes
    remove_column :tours, :length_in_km
  end
end
