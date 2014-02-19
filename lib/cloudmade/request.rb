require 'cloudmade/exceptions'
class Cloudmade::Request
  include HTTParty
  base_uri "http://#{ROUTING_SERVER_EIP}:8180/routing/api/0.3/exportArea" # Elastic IP of routing server
  default_timeout 6600 # updated default timeout to 11 minutes since 10 minutes is waiting time to bootstrap routing server if it was down

  attr_reader :bbox, :locations

  def initialize(bbox, locations)
    @bbox = bbox
    @locations = locations
  end

  def run
    begin
      response_body = self.class.get(request_uri, :query => request_query_string)
    rescue => e
      raise Cloudmade::ServiceUnavailable.new(e.to_s)
    end
    return Cloudmade::Response.new(response_body, locations)
  end

  protected

  def request_uri
    "/%f,%f/%f,%f/foot.xml" % [bbox.se.lat,bbox.se.lng,bbox.nw.lat,bbox.nw.lng]
  end

  def request_query_string
    poi_query = []
    locations.each_with_index{ |location, index| poi_query << ('poi=%i/%f/%f' % [index, location.lat, location.lng]) }
    'extendBbox=true&lang=en&callbackURI=http://google.com&sync=true&%s' % [poi_query.join('&')]
  end

  def self.for_tour(t)
    if t.is_a?(Numeric)
      Cloudmade::Request.for_tour(Tour.find(t))
    else
      Cloudmade::Request.new(t.bbox, t.location_coords)
    end
  end
end
