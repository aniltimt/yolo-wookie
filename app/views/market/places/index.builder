xml.instruct!

xml.places(:count => @places.size) do
  @places.each_pair do |country, country_tours|
    country_cities = country_tours.map(&:city).uniq
    xml.country(:name => country, :citiesCount => country_cities.size, :toursCount => country_tours.size) do
      country_cities.each do |city|
        xml.city :name => city, :toursCount => Tour.in_country(country).in_city(city).published.count, :url => market_country_city_path(country, city)
      end
    end
  end
end
