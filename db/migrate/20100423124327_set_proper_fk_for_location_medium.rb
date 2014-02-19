class SetProperFkForLocationMedium < ActiveRecord::Migration
  def self.up
    rename_column :location_media, :media_id, :medium_id
  end

  def self.down
    rename_column :location_media, :medium_id, :media_id
  end
end
