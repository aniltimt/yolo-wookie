class CreateTours < ActiveRecord::Migration
  def self.up
    create_table :tours do |t|
      t.string :name
      t.string :city
      t.string :country
      t.text :overview
      t.string :info
      t.string :thumbnail_file_name
      t.string :thumbnail_file_size

      t.timestamps
    end
  end

  def self.down
    drop_table :tours
  end
end
