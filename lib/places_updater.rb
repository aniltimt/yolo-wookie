class PlacesUpdater
  @queue = '*'

  def self.perform
    @places = Tour.published.group_by { |t| t.country }
    
    places_xml = ""
    
    xml = Builder::XmlMarkup.new(:target => places_xml)
    
    comment = "ENV: #{Rails.env}\n" <<
      "Path: #{Rails.root}\n\n"
    
    skipped_tours = []
    
    xml.instruct!
    xml.places(:count => @places.size) do
      @places.each_pair do |country, country_tours|
        country_cities = country_tours.map(&:city).uniq
        xml.country(:name => country, :citiesCount => country_cities.size, :toursCount => country_tours.size) do
          country_cities.each do |city|
            tours_in_city = Tour.in_country(country).in_city_strict(city).published
            xml.city :name => city, :toursCount => tours_in_city.count do
              tours_in_city.each do |tour|
                if tour.builds.empty?
                  skipped_tours << tour.id
                  next
                end
                # we should sort by build id not created_at date since ubertours' builds could have the same time of creation
                tour_builds = tour.builds.sort{|m,n| m.id <=> n.id}
                last_build = tour_builds.size > 1 ? tour_builds[-2] : tour_builds.last # temporary measure

                opts = {
                  :name => tour.name,
                  :is_ubertour => tour.is_ubertour, 
                  :url => last_build.tour_xml_s3_url,
            			:tourID => tour.id,
            			:latestBuild => last_build.id,
                  :client_id => (tour.user.client.market_client_id rescue nil),
                  :subtours_count => (tour.is_ubertour ? tour.children.count : 0),
                  :subtours => (tour.is_ubertour ? tour.children.collect{|subtour| subtour.id}.join(',') : '')
                }
                xml.tour(opts)
              end
            end
          end
        end
      end
    end
    
    unless skipped_tours.empty?
      comment << "Skipped tours:\n#{skipped_tours.inspect}\n"
    end
    
    xml.comment! comment

    AWS::S3::S3Object.store('places.xml', places_xml, S3_BUCKET_NAME)
  end
end
