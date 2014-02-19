require 'spec_helper'

describe PlacesUpdater do
  before do
    AWS::S3::S3Object.delete('places.xml', S3_BUCKET_NAME)
  end
  it "should upload places.xml to s3" do
    PlacesUpdater.perform
    AWS::S3::S3Object.exists?('places.xml', S3_BUCKET_NAME).should be_true
    
    AWS::S3::S3Object.delete('places.xml', S3_BUCKET_NAME)
  end
end
