require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe TourPackage, "bbox" do
  before(:each) do
    location1 = Factory.build :location
    location2 = Factory.build :location
    tour = Factory.build :tour, :locations => [location1, location2]
    @package = Factory :dummy_package, :tour => tour
  end

  it "belongs to tour" do
    @package.should belong_to(:tour)
  end

  it "consists of values of north, west, south, east" do
    @package.bbox.should == Geometry::BBox.new(Geometry::LatLng.new(@package.south, @package.east),
                                               Geometry::LatLng.new(@package.north, @package.west))
  end
end

describe TourPackage, "s3 integration" do
  before :each do
    tour = Factory :tour, :tour_locations => 2.times.map{ TourLocation.new(:location => Factory(:location), :position => 1) }
    tour.reload

    package_builder = PackageBuilder.new(tour, :platform_id => PLATFORMS::IPHONE3)
    bbox = Geometry::BBox.new(Geometry::LatLng.new(50.3333, 49.3313), Geometry::LatLng.new(51.22222, 55.333242))
    tileset = TileLoader::Tileset.new(bbox, 14, [TileLoader::Tile.new(File.open(Rails.root.join('spec', 'fixtures', '10.png').to_s).read, 54.243424, 12.444, 14)])
 
    package_builder.add_tileset tileset
    @package = package_builder.build!
    @package.save!
  end

  after(:all) do
    @package.destroy_s3_files if !Rails.env.production? && @package
  end

  it "should be xml of the tour" do
    File.exists?(@package.tour_xml_path).should be
  end

  it "should copy tour's files to S3" do
    TourPackage.initialize_s3
    #puts 'AWS::S3::Bucket.objects(@package.current_s3_bucket) - ' + AWS::S3::Bucket.objects(@package.current_s3_bucket).inspect

    AWS::S3::S3Object.exists?(@package.tour_pack_s3_uri, @package.current_s3_bucket).should be
    @package.tour.locations.each do |location|
      AWS::S3::S3Object.exists?(location.s3_icon_uri, @package.current_s3_bucket).should be
    end
    AWS::S3::S3Object.exists?(@package.tour_xml_s3_uri, @package.current_s3_bucket).should be
  end
end

describe TourPackage, "contents" do
  before(:each) do
    location1 = Factory.build :location
    location2 = Factory.build :location
    tour = Factory.build :tour, :locations => [location1, location2]
    @package = Factory.build :dummy_package, :tour => tour
    %w(foo bar baz).each { |f| @package.add_file(f, f) }
    @package.add_overall_tour_map([])
    @package.save!
  end

  it "is a list of it's files and directories" do
    @package.contents.should == Dir["#{@package.content_root}/**/**"]
  end

  it "should contain 9 tiles of the city in one zoom level" do
    9.times do |i|
      @package.contents.should include(Rails.root.join('public','builds', @package.id.to_s, 'content', 'map', 'tiles', 'city_tiles', "#{i}.png").to_s)
    end
  end

  it "gets erased after destroying the package" do
    contents = @package.contents
    @package.destroy
    contents.each{ |ent| File.exist?(ent).should be_false}
  end
end
