require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))
=begin
describe "Creating new tour in", ToursController do
  integrate_views

  before(:each) do
    @location = Factory :location
    @tour_params = Factory.attributes_for(:tour)
  end

  describe "by posting with correct attributes" do
    before(:each) do
      @opts = {:tour_locations_attributes => [{:id => '', :location_id => @location.id, :_destroy => false, :position => 1}]}
    end

    it "creates one tour" do
      visit 'new'
      fill_in 'tour_name', :with => Faker::Lorem.sentence
      select "Ukraine", :from => 'tour_country'
      fill_in 'tour_city', :with => Faker::Address.city
      fill_in 'tour_overview', :with => Faker::Lorem.paragraph
      fill_in 'tour_info', :with => Faker::Lorem.sentence
      #click_button 'Save'
      lambda { do_create(@opts) }.should change(Tour, :count).by(1)
    end

    it "redirects to /tour/:id" do
      do_create(@opts)
      response.should redirect_to(tour_path(created_tour))
    end

    it "creates one TourLocation record for each given tour locations attributes" do
      TourLocation.destroy_all
      do_create(@opts)
      created_tour.should have(1).tour_locations
    end

    xit "associates each location with created tour" do
      do_create
      tour = created_tour
      @opts[:tour_locations_attributes].each do |tla|
        tour.tour_locations.find_by_position_and_location_id(tla[:position], tla[:location_id]).should_not be_nil
      end
    end
  end

  private
  def do_create(opts={})
    post :create, :tour => @tour_params.merge(opts)
  end

  def created_tour
    Tour.find_by_name(@tour_params[:name])
  end
end
=end
