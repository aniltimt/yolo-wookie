require 'spec_helper'

describe Geometry::LatLng do
  describe "can be constructed from" do
    it "two separate values" do
      x = construct(1, 2)
      x.lat.should == 1
      x.lng.should == 2
    end

    it "hash" do
      x = construct({'lat' => 10, 'lng' => 20})
      x.lat.should == 10
      x.lng.should == 20
    end

    it "any object responding to :lat and :lng" do
      x = construct(OpenStruct.new(:lat => 10, :lng => 20))
      x.lat.should == 10
      x.lng.should == 20
    end
  end

  it "raises ArgumentError on unsuccessfull construction" do
    lambda {construct("something invalid")}.should raise_error(ArgumentError)
  end

  it "casts initializing values to floats" do
    x = construct('lat' => '100', 'lng' => '100000')
    x.lat.should be_eql('100'.to_f)
    x.lng.should be_eql('100000'.to_f)
  end

  it "coordinates are concatenated to form string representation" do
    construct(100, 100).to_s.should == "100.0, 100.0"
  end

  it "is hashed by it's string representation" do
    x=construct(100, 100)
    x.hash.should == x.to_s.hash
  end


  private

  def construct(*args)
    Geometry::LatLng.new(*args)
  end
end
