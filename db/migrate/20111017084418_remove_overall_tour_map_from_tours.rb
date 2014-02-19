class RemoveOverallTourMapFromTours < ActiveRecord::Migration
  def self.up
    remove_column :tours, :overall_tour_map_file_name
    remove_column :tours, :overall_tour_map_file_size
    remove_column :tours, :overall_tour_map_content_type
  end

  def self.down
    add_column :tours, :overall_tour_map_file_name, :string
    add_column :tours, :overall_tour_map_file_size, :integer
    add_column :tours, :overall_tour_map_content_type, :string
  end
end
