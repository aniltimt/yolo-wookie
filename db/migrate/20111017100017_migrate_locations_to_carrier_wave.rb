class MigrateLocationsToCarrierWave < ActiveRecord::Migration
  def self.up
    rename_column :locations, :thumbnail_file_name, :thumbnail
  end

  def self.down
    rename_column :locations, :thumbnail, :thumbnail_file_name
  end
end
