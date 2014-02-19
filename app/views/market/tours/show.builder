xml.instruct!

xml.tour(:country => @build.country, :city => @build.city) do
  xml.name @build.tour_name
  xml.locationsCount @build.locations_count
  xml.files(:mapUrl => map_market_tour_path(@tour, :format => :bin), :mediaUrl => media_market_tour_path(@tour, :format => :bin), :tourID => @tour.id, :locationsCount => @build.locations_count)
end
