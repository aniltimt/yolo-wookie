class AddTourBoundingBox < ActiveRecord::Migration
  def self.up
    add_column :tours, :overall_tour_map_file_name, :string
    add_column :tours, :overall_tour_map_file_size, :integer
    add_column :tours, :overall_tour_map_content_type, :string
  end

  def self.down
    remove_column :tours, :overall_tour_map_file_name
    remove_column :tours, :overall_tour_map_file_size
    remove_column :tours, :overall_tour_map_content_type
  end
end
