class CreateLocationDetails < ActiveRecord::Migration
  def self.up
    create_table :location_details do |t|
      t.string :name, :null => false
      t.text :description

      t.string :attachment_file_name
      t.string :attachment_content_type
      t.string :attachment_file_size

      t.string :type, :null => false
      t.integer :location_id, :null => true

      t.timestamps
    end
  end

  def self.down
    drop_table :location_details
  end
end
