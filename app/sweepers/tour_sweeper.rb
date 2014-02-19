class TourSweeper < ActionController::Caching::Sweeper
  observe Tour

  def expire_tours
    %w(published draft building edited failed).each do |state|
      expire_fragment("all_#{state}_tours")
    end
    expire_fragment("all_tours")
  end

  def after_create(tour)
    expire_tours
  end

  def after_update(tour)
    expire_tours
  end

  def after_destroy(tour)
    expire_tours
  end
end
