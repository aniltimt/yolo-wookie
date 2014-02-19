class CreateTourLocations < ActiveRecord::Migration
  def self.up
    create_table :tour_locations do |t|
      t.integer :tour_id, :null => false
      t.integer :location_id, :null => false
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :tour_locations
  end
end
