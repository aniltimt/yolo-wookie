require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe "Ubertour" do
  before do
    @tour1 = Factory :tour, :tour_locations => 2.times.map{|i| TourLocation.new(:location => Factory(:location), :position => (i + 1))}
    @tour2 = Factory :tour, :tour_locations => 2.times.map{|i| TourLocation.new(:location => Factory(:location), :position => (i + 1))}
    @tour3 = Factory :tour, :tour_locations => 2.times.map{|i| TourLocation.new(:location => Factory(:location), :position => (i + 1))}
  end

  describe "creating the ubertour" do
    before do
      @ubertour = Tour.create :name => "Ubertour #1", :overview => "ubertour in UK", :info => "test", :country => "UK", :city => "London", :length_in_km => 105, :length_in_minutes => 246, :user_id => 1, :is_ubertour => true
      @ubertour2 = Tour.create :name => "Ubertour #2", :overview => "ubertour in UK", :info => "test", :country => "UK", :city => "London", :length_in_km => 15, :length_in_minutes => 100, :user_id => 2, :is_ubertour => true
      @ubertour.should be
      @ubertour2.should be
      [@tour1, @tour2].each_with_index{|tour, i| TourUbertour.create!(:tour_id => tour.id, :ubertour_id => @ubertour.id, :position => (i+1)) }
      [@tour3, @tour2].each_with_index{|tour, i| TourUbertour.create!(:tour_id => tour.id, :ubertour_id => @ubertour2.id, :position => (i+1)) }
    end

    it "should have many tours" do
      @ubertour.children.count.should == 2
      @ubertour.children.should =~ [@tour1, @tour2]
    end

    it "one tour could belong to different ubertours" do
      @ubertour2.children.count.should == 2
      @ubertour2.children.should =~ [@tour3, @tour2]
    end
  end
end
