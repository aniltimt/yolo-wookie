require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))
require 'ftools'

describe "successfully built medium", :shared => true do
  it "constructs valid model" do
    @medium.save.should be_true
  end

  it "sets description" do
    @medium.credits.should == @detail_params[:credits]
  end

  it "sets name" do
    @medium.name.should == @detail_params[:name]
  end

  it "sets country" do
    @medium.country.should == @detail_params[:country]
  end
end

describe Medium do
  it "has many location" do
    should have_many(:locations)
  end

  it "should provide interface to search on name and description" do
    @medium = Picture.create({:name => "Google", :tag_list => "tag", :country => "UK", :credits => "CC", :attachment => File.open('spec/fixtures/media/google-poster.jpg')})

    Medium.count.should == 1
    Medium.search("Google").should have(1).record
    Medium.search("Google")[0].name.should == @medium.name

    #Medium.search("CC").should have(1).record
    # description field not yet in html interface
    #Medium.search("Creator of Ruby")[0].description.should == @medium.description
  end
end

describe "Building", Medium, "with no attached file given" do
  before(:each) do
    @detail_params = detail_params.merge!({:country => "UK"})
    @medium = Medium.build_from_params(@detail_params)
  end

  it "constructs Medium" do
    @medium.should be_instance_of(Medium)
  end

  it "results in incorrect model" do
    @medium.save.should be_false
  end
end

[:name, :country].each do |attribute|
  describe "Building", Medium, "without #{attribute}" do
    before(:each) do
      @detail_params = detail_params :attachment => File.open('spec/fixtures/media/pylesos.jpg'), :country => "UK"
      @detail_params.delete(attribute)
      @medium = Medium.build_from_params(@detail_params)
    end
    
    it "results in incorrect model" do
      @medium.should_not be_valid
    end
  end
end

describe "Building", Medium, "with video file given" do
  before(:each) do
    @detail_params = detail_params :attachment => File.open('spec/fixtures/media/romania.avi'), :country => "UK"
    @medium = Medium.build_from_params(@detail_params)
  end

  it_should_behave_like "successfully built medium"

  it "constructs Video" do
    @medium.should be_instance_of(Video)
  end

  it "attaches given file to model" do
    @medium.save
    @medium.attachment.path.should =~ /romania\.avi/
  end
end

describe "Building ", Medium, "with image given" do
  before(:each) do
    @detail_params = detail_params :attachment => File.open('spec/fixtures/media/pylesos.jpg'), :country => "UK"
    @medium = Medium.build_from_params(@detail_params)
  end

  it_should_behave_like "successfully built medium"

  it "constructs Picture" do
    @medium.should be_instance_of(Picture)
  end

  it "attaches given file to model" do
    @medium.save
    @medium.attachment.path.should =~ /pylesos\.jpg/
  end
end

describe "TextPage", Medium do
  before(:each) do
    @file = File.open('spec/fixtures/media/test_document.txt')
    @detail_params = detail_params :attachment => @file, :country => "UK"
    @medium = Medium.build_from_params(@detail_params)
  end

  it_should_behave_like "successfully built medium"
  
  it "should xmlize attached file" do
    @medium.save
    File.read(@medium.attachment.path).should include("<?xml")
  end
end

describe "Hash of", Medium do
  before(:each) do
    @file = File.open('spec/fixtures/media/pylesos.jpg')
    @medium = Medium.build_from_params(detail_params(:attachment => @file, :country => "UK"))
    @medium.save!
  end

  it "is calculated while saving" do
    @medium.attachment.should_not be_blank
    @medium.attachment.fingerprint.should_not be_blank
  end

  it "is class of Paperclip::Attachment and atachment_finterprint is MD5 of given file" do
    @medium.attachment.class.should == Paperclip::Attachment
    #@medium.attachment_fingerprint.should == Digest::MD5.hexdigest(File.read("spec/fixtures/media/pylesos.jpg"))
  end

  it "should be unique" do
    same_medium = Medium.build_from_params(detail_params(:attachment => @file))
    same_medium.save
    same_medium.errors.on(:attachment_fingerprint).should_not be_empty
  end
end

describe "Keywords for", Medium do
  before(:each) do
    @file = File.open('spec/fixtures/media/pylesos.jpg')
    @medium = Medium.build_from_params(detail_params(:attachment => @file, :country => "UK", :tag_list => ["pylesos", "static"]))
    @medium.save!
  end

  it "should return tag lists" do
    @medium.tag_list.should =~ ["pylesos", "static"]
  end
end

def detail_params(opts={})
  {
    :credits => Faker::Lorem.paragraph,
    :name => Faker::Lorem.sentence,
    :tag_list => Faker::Lorem.sentence
  }.merge(opts)
end
