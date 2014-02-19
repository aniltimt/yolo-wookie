class AddFieldsToTourPackages < ActiveRecord::Migration
  NEW_FIELDS =  {
    :tour_name => :string,
    :locations_count => :int,
    :city => :string,
    :country => :string
  }

  def self.up
    NEW_FIELDS.each_pair do |field, field_type|
      add_column :tour_packages, field, field_type
    end

    remove_column :tour_packages, :content
  end

  def self.down
    NEW_FIELDS.each_pair do |field, field_type|
      remove_column :tour_packages, field
    end
    add_column :tour_packages, :content, :text
  end
end
