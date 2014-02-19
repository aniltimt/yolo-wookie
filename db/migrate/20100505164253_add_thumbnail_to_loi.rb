class AddThumbnailToLoi < ActiveRecord::Migration
  def self.up
    add_column :locations, :thumbnail_file_name, :string
  end

  def self.down
    remove_column :locations, :thumbnail_file_name
  end
end
