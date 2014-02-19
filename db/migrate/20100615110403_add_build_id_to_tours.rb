class AddBuildIdToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :build_id, :integer
  end

  def self.down
    remove_column :tours, :build_id
  end
end
