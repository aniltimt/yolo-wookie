class TourLocation < ActiveRecord::Base
  acts_as_list :scope => :tour_id

  belongs_to :tour
  belongs_to :location
  
#  validates_uniqueness_of :location_id, :scope => :tour_id

  default_scope :order => "position asc"

  named_scope :with_locations, :order => :position, :joins => :location

end
