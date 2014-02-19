class LocationMedium < ActiveRecord::Base
  belongs_to :location
  belongs_to :medium

  validates_presence_of :location_id, :medium_id
  validates_uniqueness_of :medium_id, :scope => :location_id
end
