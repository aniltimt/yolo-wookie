class ExtendLocationsModel < ActiveRecord::Migration
  def self.up
# id: integer, name: string, description: text, lat: float, lng: float, created_at: datetime, updated_at: datetime
    add_column :locations, :country, :string
    add_column :locations, :city, :string
    add_column :locations, :comment, :string
    add_column :locations, :short_description, :text
    rename_column :locations, :description, :full_description
    add_column :locations, :address, :string
    add_column :locations, :phone, :string
    add_column :locations, :website, :string
    add_column :locations, :email, :string
    add_column :locations, :opening_hours, :string
    add_column :locations, :entrance_fee, :string
    add_column :locations, :nearest_transport, :string
  end

  def self.down
    remove_column :locations, :country
    remove_column :locations, :city
    remove_column :locations, :comment
    remove_column :locations, :short_description
    rename_column :locations, :full_description, :description
    remove_column :locations, :address
    remove_column :locations, :phone
    remove_column :locations, :website
    remove_column :locations, :email
    remove_column :locations, :opening_hours
    remove_column :locations, :entrance_fee
    remove_column :locations, :nearest_transport
  end
end
