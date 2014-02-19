class AddLastBuiltAtToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :last_built_at, :datetime
    Tour.all.each{|t| t.update_attribute(:last_built_at, t.builds.first.updated_at) unless t.builds.empty?}
  end

  def self.down
    remove_column :tours, :last_built_at
  end
end
