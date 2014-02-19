require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe Location, "named scope" do
  before(:each) { 10.times{ Factory :location }}

  it "in_city returns only records within given cities" do
    city = Location.first.city
    Location.in_city(city).should == Location.all(:conditions => { :city => city})
  end

  it "in_country returns only records within given country" do
    country = Location.first.country
    Location.in_country(country).should == Location.all(:conditions => { :country => country})
  end

  it "country_cities returns list of cities and their countries" do
    locations = Location.all(:select => "id, city, country", :group => "city", :order => "city asc")
    locations.size.should == Location.country_cities.size
    locations.each{|l| Location.country_cities.should include(l)}
  end

  it "country_cities is wrapped into Location#places call" do
    Location.country_cities.group_by(&:country).should == Location.places
  end
end

describe "Position of", Location do
  before(:each) { @location = Factory(:location); @position = @location.latlng}

  it "returns properly set attributes" do
    @position.lat.should == @location.lat
    @position.lng.should == @location.lng
  end
end
