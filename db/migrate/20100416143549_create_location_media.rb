class CreateLocationMedia < ActiveRecord::Migration
  def self.up
    create_table :location_media do |t|
      t.integer :media_id, :null => false
      t.integer :location_id, :null => false
    end

    remove_column :media, :location_id
  end

  def self.down
    add_column :media, :location_id, :integer, :null => false
    drop_table :location_media
  end
end
