require 'cloudmade/exceptions'
class Cloudmade::Response
  attr_reader :data
  attr_reader :area, :segments, :pois, :bbox

  def initialize(data, locations)
    assert_valid_response data
    @locations = locations
    @data = data['export']
    @area = @data['area']
    @segments = parse_segments(area['segments']['segment'])
    poi_list = if @data['pois']['poi'].is_a?(Hash)
     [ @data['pois']['poi'] ]
    else
      @data['pois']['poi']
    end

    @pois = Hash[*poi_list.map{ |p| [p['id'], Geometry::LatLng.new(p['lat'], p['lng'])] }.flatten]
  end

  def successful?
    @data.is_a?(Hash)
  end

  def bbox
    bbox = area['effectiveBbox']
    se = bbox['southeast']
    nw = bbox['northwest']
    Geometry::BBox.new(Geometry::LatLng.new(se['lat'].to_f/100000, se['lng'].to_f/100000),
                       Geometry::LatLng.new(nw['lat'].to_f/100000, nw['lng'].to_f/100000))
  end

  def routes
    return [] if @data['routes'].blank? && (@locations.size == 1)

    raise Cloudmade::RoutesUnavailable if @data['routes'].nil?

    @routes ||= @data['routes']['route'].map do |route|
      # [DF-281] if route is too small cloudmade returns only hash with 1 route (single line I guess), otherwise array of routes 
      direction_ref_id = if route['segments']['segment'].is_a?(Hash)
        [[route['segments']['segment']['direction'], route['segments']['segment']['ref_id']]]
      elsif route['segments']['segment'].is_a?(Array)
        route['segments']['segment'].map{ |s| [s['direction'], s['ref_id']]}
      end
      Geometry::Route.new(pois[route['start_poi']], pois[route['end_poi']], direction_ref_id)
    end
  end

  def check_for_unused_points_in_prerouting
    pois_present = []

    return if @data['routes'].blank? && (@locations.size == 1)

    if @data['routes'].blank?
      raise Cloudmade::PoiAbsentInPrerouting, "One of the LOIs is unreachable. Please move or delete LOI #1 or LOI #2 pin from the tour"
    else
      @data['routes']['route'].map do |route|
        pois_present << route['start_poi'].to_i << route['end_poi'].to_i
      end
    
      @pois.size.times do |i|
        raise Cloudmade::PoiAbsentInPrerouting, "LOI ##{i+1} is unreachable. Please move LOI ##{i+1} pin or delete this LOI ##{i+1} from the tour" if ! pois_present.uniq.include?(i)
      end
    end
  end

  private

  def parse_segments(segments_list)
    segments_list.map{ |seg| Geometry::Segment.new(seg) }
  end


  def assert_valid_response(assert_data)
    raise Cloudmade::MalformedResponse.new(assert_data) if
      assert_data.is_a?(String) ||
      !assert_data.respond_to?('[]') ||
      assert_data['export'].blank? ||
      assert_data['export']['area'].blank?
  end
end
