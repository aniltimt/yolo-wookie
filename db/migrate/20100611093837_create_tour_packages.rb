class CreateTourPackages < ActiveRecord::Migration
  def self.up
    create_table :tour_packages do |t|
      t.integer :tour_id
      t.text :content
      t.integer :version

      t.float :south, :east, :north, :west

      t.timestamps
    end
  end

  def self.down
    drop_table :tour_packages
  end
end
