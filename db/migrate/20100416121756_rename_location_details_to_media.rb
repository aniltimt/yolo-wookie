class RenameLocationDetailsToMedia < ActiveRecord::Migration
  def self.up
    rename_table :location_details, :media
  end

  def self.down
    rename_table :media, :location_details
  end
end
