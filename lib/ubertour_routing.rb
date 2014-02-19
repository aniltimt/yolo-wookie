class UbertourRouting
  include HTTParty

  base_uri 'open.mapquestapi.com'
  default_timeout 60

  attr_accessor :bbox

  def initialize(ubertour_id)
    @ubertour = Tour.find ubertour_id
  end

  def calculate
    if @ubertour.is_ubertour
      tours = @ubertour.children
      from_point = [tours.first.center.lat, tours.first.center.lng].join(',')

      to_points = ''
      if tours.count > 2
        to_points += tours[1..-2].collect{|tour| [tour.center.lat, tour.center.lng].join(',') }.map!{|tpoints| "to=#{tpoints}"}.join('&') + '&'
      end
      
      to_points += "to=#{[tours.last.center.lat, tours.last.center.lng].join(',')}"

      route_type = if @ubertour.ubertour_route_type.eql?("car")
        "shortest"
      elsif @ubertour.ubertour_route_type.eql?("foot")
        "pedestrian"
      end

      request_string = "/guidance/v0/route?from=#{from_point}&#{to_points}&narrativeType=text&fishbone=false&outFormat=xml&routeType=#{route_type}"
      response = self.class.get(request_string)

      coords = []

      begin
        count = response["response"]["guidance"]["shapePoints"]["lng"].count
      rescue => e
        # there is no "shapePoints" in response
        raise Cloudmade::RoutesUnavailable
      end

      (0..(count-1)).map do |i|
        lng = response["response"]["guidance"]["shapePoints"]["lng"][i]
        lat = response["response"]["guidance"]["shapePoints"]["lat"][i]
        coords << [lat, lng]
      end

      bbox = response["response"]["guidance"]["boundingBox"]
      nw = ::Geometry::LatLng.new(bbox["ul"]["lat"], bbox["ul"]["lng"]) 
      se = ::Geometry::LatLng.new(bbox["lr"]["lat"], bbox["lr"]["lng"])
      self.bbox = ::Geometry::BBox.new(se, nw)

      route_xml = ""
      xml = Builder::XmlMarkup.new(:target => route_xml)
      xml.instruct!
      xml.route do |route|
        coords.each do |coord|
          route.point(:lng => coord[0], :lat => coord[1])
        end
      end
      route_xml
    end
  end
end
