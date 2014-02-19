class AddRouteTypeForUbertours < ActiveRecord::Migration
  def self.up
    add_column :tours, :ubertour_route_type, :string, :default => "foot"
  end

  def self.down
    remove_column :tours, :ubertour_route_type
  end
end
