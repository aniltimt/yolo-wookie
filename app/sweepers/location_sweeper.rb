class LocationSweeper < ActionController::Caching::Sweeper
  observe Location

  def after_update(location)
    expire_location_and_related_tour_fragments(location)
  end

  def after_destroy(location)
    expire_location_and_related_tour_fragments(location)
  end

  protected
    def expire_location_and_related_tour_fragments(location)
      expire_fragment(:action => 'index', :controller => 'locations', :key => "lfragm_#{location.id}")
      if ! location.tours.blank?
        location.tours.each do |tour|
          expire_fragment(:action => 'index', :controller => 'tours', :key => "tfragm_#{tour.id}")
        end
      end
    end
end
