require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe Tour do
  subject do
    @loc1 = Factory(:location)
    Factory :tour, :tour_locations => [TourLocation.new(:location => @loc1, :position => 1)]
  end

  it { should be_valid }
  it { should have_many(:tour_locations) }
  it { should be_draft }

  it "should have correct bbox" do
    subject.reload
    ("%.7f" % subject.bbox.se.lat).should == ("%.7f" % (@loc1.lat - BBOX_PADDING.to_f))
    ("%.7f" % subject.bbox.se.lng).should == ("%.7f" % (@loc1.lng + BBOX_PADDING.to_f))
    ("%.7f" % subject.bbox.nw.lat).should == ("%.7f" % (@loc1.lat + BBOX_PADDING.to_f))
    ("%.7f" % subject.bbox.nw.lng).should == ("%.7f" % (@loc1.lng - BBOX_PADDING.to_f))
  end
end

describe "Finding", Tour, "with named scope" do
  before(:each) do
    10.times { Factory :tour, :tour_locations => [TourLocation.new(:location => Factory(:location), :position => 1), TourLocation.new(:location => Factory(:location), :position => 1)] }
  end

  it "in_city returns all tours in given city" do
    city = Tour.first.city
    Tour.in_city(city).should == Tour.all(:conditions => { :city => city})
  end

  it "in_country returns all tours in given country" do
    country = Tour.first.country
    Tour.in_country(country).should == Tour.all(:conditions => { :country => country })
  end
end

describe "Categories of", Tour do
  before(:each) do
    @categories = Faker::Lorem.words(4)
    3.times do
      tour = Factory.build :tour
      4.times{ tour.tour_locations << TourLocation.new(:location => Factory(:location, :category_list => 2.times.map{@categories.rand}.join(",")), :position => 1) }
      tour.save!
    end
  end

  it "are categories of all of it's locations" do
    Tour.all.each{ |tour| tour.categories.sort.should == tour.locations.map{|l| l.category_list }.flatten.uniq.sort }
  end

  it "can be used to filter tours selection" do
    @categories.each do |category|
      scoped_tours = Tour.by_category(category).all(:order => "id asc")
      filtered_tours = Tour.all(:order => "id asc").select{|t| t.locations.map(&:category_list).flatten.include?(category)}
      scoped_tours.should == filtered_tours
    end
  end
end

describe "Bounding box of", Tour do
  before(:each) { @tour = Factory(:tour, :tour_locations => 5.times.map{ TourLocation.new(:location => Factory(:location), :position => 1) }); @tour.reload; @bbox = @tour.bbox; }

  it "is instance of Geometry::BBox" do
    @bbox.should be_instance_of(Geometry::BBox)
  end

  it "N of bbox should be northmost point of tour's locations" do
    @bbox.se.lat.should == @tour.locations.map(&:lat).min
  end

  it "E of bbox should be eastmost point of tour's locations" do
    @bbox.se.lng.should == @tour.locations.map(&:lng).max
  end

  it "S of bbox is a southmost point of tour's locations" do
    @bbox.nw.lat.should == @tour.locations.map(&:lat).max
  end
  it "W of bbox is a westmost point of tour's locations" do
    @bbox.nw.lng.should == @tour.locations.map(&:lng).min
  end
end

describe "State of", Tour do
  before(:each) do
    Resque.stub(:enqueue).and_return(true)
    @tour_location1 = TourLocation.new(:location => Factory(:location), :position => 1)
    @tour_location2 = TourLocation.new(:location => Factory(:location), :position => 1)
    @tour = Factory :tour, :tour_locations => [@tour_location1, @tour_location2]
    @tour_location2.save
    @tour_location1.save
    @tour.reload
  end

  it "is draft by default" do
    @tour.should be_draft
  end

  it "can be transitioned to building" do
    @tour.build!
    @tour.should be_building
  end

  it "is reverted back to draft when build is failed" do
    @tour.build!
    @tour.build_failed!
    @tour.should be_failed
  end

  it "is transitioned to published when build succeeds" do
    @tour.build!
    @tour.publish!
    @tour.should be_published
  end

  it "can be built again when published" do
    @tour.build!
    @tour.publish!
    @tour.build!
    @tour.should be_building
  end

  it "should be turned to 'edited' status when some of tour's parameters was changed" do
    @tour.build!
    @tour.publish!
    @tour.update_attributes! :name => "super new version of the tour"
    @tour.should be_edited    
  end

  it "should be turned to 'edited' status when some of tour's locations was changed" do
    @tour.build!
    @tour.publish!
    location = @tour.locations[0]
    location.update_attributes! :name => "updated name of the location"
    @tour.reload
    @tour.should be_edited    
  end
end

describe "Location positions of", Tour do
  before(:each) do
    @tour = Factory :tour, :tour_locations => 2.times.map{TourLocation.new(:location => Factory(:location), :position => 1) }
    3.times{ @tour.tour_locations.first.move_to_bottom }
  end

  it "are returned ordered by location's position" do
    @tour.location_coords.should == @tour.tour_locations(:order => "position asc").map{ |x| x.location.latlng }
  end
end


describe Tour, "is not obsolette when" do
  before(:each) do
    @tour = Factory :tour, :tour_locations => 2.times.map{TourLocation.new(:location => Factory(:location), :position => 1)}, :last_built_at => 3.minutes.from_now
    @tour.locations = 3.times.map{Factory :location}
    @build = Factory :dummy_package, :tour => @tour
  end

  it "no changes were made to tour's components after the creation of build" do
    @tour.should_not be_obsolete
  end
end

describe Tour, "is obsolette when" do
  before(:each) do
    location = Factory(:location)
    @tour = Factory :tour, :tour_locations => 2.times.map{TourLocation.new(:location => location, :position => 1)}
    @tour.reload
  end

  it "it has no builds" do
    @tour.should be_obsolete
  end

  describe "when after building the tour" do
    before(:each) do
      @location = @tour.locations.first
      @build = Factory :dummy_package, :tour => @tour
    end

    it "it's data have been modified" do
      @tour.update_attribute(:name, "FUBAR")
      @tour.reload.should be_obsolete
    end

    it "it's location data have been modified" do
      @location.update_attribute(:name, "FUBAR")
      @tour.reload.should be_obsolete
    end

    xit "it's location's media have been modified" do
    end
  end
end

describe "Checking whether area of", Tour, "is too big returns" do
  before(:each) do
    @locations = 2.times.map {Factory :location}
    @tour = Factory.build :tour, :tour_locations => @locations.map{|l| TourLocation.new(:location => l, :position => 1)}
  end

  it "true then both sides of bbox is less then 0.1 degrees long" do
    @locations.first.update_attributes(:lat => 0.0, :lng => 0.05)
    @locations.last.update_attributes(:lat => 0.1, :lng => -0.01)
    @tour.area_too_big?.should be_false
  end

  it "false otherwise" do
    @locations.first.update_attributes(:lat => 0.0, :lng => 0.1)
    @locations.last.update_attributes(:lat => 0.2, :lng => -0.1)
    @tour.save.should be_true
  end
end

describe "Creating", Tour, "with specified locations params" do
  before(:each) do
    @tour = Factory.build :tour, :tour_locations => 2.times.map{ TourLocation.new(:location => Factory(:location), :position => 1) } 
    #@tour.tour_locations_attributes = [{'position' => 1, 'location_id' => @location1.id}, {'position' => 2, 'location_id' => @location2.id}]
  end

  it "saves tour successfully" do
    @tour.save.should be_true 
  end

  it "creates tour with only given locations" do
    lambda{@tour.save}.should change(@tour.tour_locations, :count).by(2)
  end
end
