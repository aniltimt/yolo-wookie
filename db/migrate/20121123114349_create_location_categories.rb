class CreateLocationCategories < ActiveRecord::Migration
  def self.up
    create_table :location_categories do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :location_categories
  end
end
