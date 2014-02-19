require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe "Searching media", MediaController do
  integrate_views

  include Devise::TestHelpers

  before(:each) do
    @user = User.create!(:login => 'admin', :password => '123456', :password_confirmation => '123456')
    sign_in @user
    @medium = Picture.create({:country => "UK", :name => "Matz", :credits => "Creative Commons", :tag_list => ["matz"], :attachment => File.open('spec/fixtures/media/google-poster.jpg')})
  end

  it "should return json answer on search request" do
    post :search, :name => 'matz', :format => "json", :in_country => "UK"
    response.body.should =~ /Matz/
  end
end
