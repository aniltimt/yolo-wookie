class AddIsDraftToLocation < ActiveRecord::Migration
  def self.up
    add_column :locations, :is_draft, :boolean, :default => false
  end

  def self.down
    remove_column :locations, :is_draft
  end
end
