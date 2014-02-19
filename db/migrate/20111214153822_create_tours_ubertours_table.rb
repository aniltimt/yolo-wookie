class CreateToursUbertoursTable < ActiveRecord::Migration
  def self.up
    create_table :tour_ubertours do |t|
      t.integer :tour_id
      t.integer :ubertour_id
      t.integer :position
    end

    add_index :tour_ubertours, [:tour_id, :ubertour_id]
  end

  def self.down
    drop_table :tour_ubertours
  end
end
