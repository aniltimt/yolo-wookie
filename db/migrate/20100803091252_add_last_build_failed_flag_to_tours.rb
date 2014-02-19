class AddLastBuildFailedFlagToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :last_build_failed, :boolean
  end

  def self.down
    remove_column :tours, :last_build_failed
  end
end
