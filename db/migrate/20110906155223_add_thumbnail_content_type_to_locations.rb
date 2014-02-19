class AddThumbnailContentTypeToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :thumbnail_content_type, :string
  end

  def self.down
    remove_column :locations, :thumbnail_content_type
  end
end
