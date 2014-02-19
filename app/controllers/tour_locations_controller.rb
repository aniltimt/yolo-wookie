class TourLocationsController < ResourceController::Base
  belongs_to :tour, :collection_name => :tour_locations

  def move_up
    resource.move_higher
    redirect_to tour_locations_path(@tour)
  end

  def move_down
    resource.move_lower
    redirect_to tour_locations_path(@tour)
  end

  protected

  def collection
    get_collection_ivar || set_collection_ivar(parent.tour_locations.with_locations)
  end

end
