class AddCountryCityToMedium < ActiveRecord::Migration
  def self.up
    add_column :media, :country, :string, :null => false
    add_column :media, :city, :string

    add_index  :media, :country
    add_index  :media, [:country, :city]
  end

  def self.down
    remove_index :media, [:country, :city]

    remove_column :media, :country
    remove_column :media, :city
  end
end
