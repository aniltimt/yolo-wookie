class AddPobCategoriesFieldToTours < ActiveRecord::Migration
  def self.up
    add_column :tours, :pob_categories_ids, :string
  end

  def self.down
    remove_column :tours, :pob_categories_ids
  end
end
