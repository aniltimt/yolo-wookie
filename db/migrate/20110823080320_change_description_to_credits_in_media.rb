class ChangeDescriptionToCreditsInMedia < ActiveRecord::Migration
  def self.up
    rename_column :media, :description, :credits
  end

  def self.down
    rename_column :media, :credits, :description
  end
end
