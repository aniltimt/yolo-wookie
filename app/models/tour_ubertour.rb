class TourUbertour < ActiveRecord::Base
  belongs_to :tour, :class_name => "Tour"
  belongs_to :ubertour, :foreign_key => "ubertour_id", :class_name => "Tour"

  default_scope :order => "position asc"
end
