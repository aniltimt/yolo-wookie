require 'stringio'
class PackageBuilder

  # we include here TourHelper to use #country_from_iso_code
  include ToursHelper

  def initialize(tour, options = {})
    @tour = tour
    @vertices = Set.new
    @graph = Set.new
    @connections = Hash.new(Array.new)
    @prerouting = { }
    @tileset = Hash.new(Array.new)
    @platform_id = options[:platform_id] || 1      # 1 == iPhone
  end

  def add_segment(segment)
    segment = segment.dup
    @graph.add(segment)

    @vertices.add(segment.points.first)
    @vertices.add(segment.points.last)

    self
  end

  def add_graph_data(segments)
    segments.each{ |segment| add_segment(segment) }
    self
  end

  def set_prerouting(routes)
    @prerouting = routes
    self
  end

  def add_osm_routing(osm_routing_bin)
    @osm_routing_file = osm_routing_bin
  end

  def add_tileset(tileset)
    @tileset[tileset.zoom] = tileset
    self
  end

  def build!

    package = TourPackage.new(:tour => @tour, :platform_id => @platform_id)

    if :cloudmade == ROUTING_METHOD
      routing_data = ""
      prerouting_data = ""

      check_routes_for_missing_segments

      io = StringIO.new(prerouting_data)
      write_prerouting(io)
      package.add_map_file('routes/prerouting.bin', prerouting_data)

      io = StringIO.new(routing_data)
      write_cached_points(io)
      write_graph_edges(io)
      write_graph_connections(io)
      package.add_map_file('routes/routing.bin', routing_data)
    end

    if @osm_routing_file && File.exists?(@osm_routing_file.path) && (:osm == ROUTING_METHOD)
      package.add_map_file('routes/routing.bin', File.read(@osm_routing_file.path))
    end

    @tileset.each_pair do |zoom_level, tileset|
      write_tileset package, tileset, 'tiles'
    end

    Rails.logger.warn '@tileset.min.last.bbox = ' + @tileset.min.last.bbox.inspect
    package.bbox = @tileset.min.last.bbox #@tileset[platform_zoom_levels.first].bbox

    city_bbox = Tour.get_city_bbox(country_from_iso_code(@tour.country), @tour.city)
    tileset_for_overall_city = package.add_overall_tour_map(city_bbox, :platform_id => @platform_id)

    map_xml = generate_map_xml(package.bbox, @tileset, city_bbox, tileset_for_overall_city)
    package.add_map_file(package.map_xml_name, map_xml)

    tour_xml = generate_tour_xml(@tour, city_bbox)
    package.add_file(package.tour_xml_name, tour_xml)

    return package
  end

  private

  def write_cached_points(io)
    io.write [@vertices.size].pack("N")
    @vertices.each{ |vertex| write_vertex(io, vertex) }
  end

  def write_graph_edges(io)
    io.write [@graph.size].pack("N")

    @graph.each do |s|
      io.write [s.length, s.points.size].pack("gN")
      io.write [@vertices.find_index(s.points.first), @vertices.find_index(s.points.last)].pack("NN")
      s.points[1..-2].each{ |p| write_vertex(io, p) }
    end
  end

  def write_vertex(io, ll)
    io.write [ll.lng.to_i*10, ll.lat.to_i*10].pack("NN")
  end

  def store_connections(point, ref_ids)
    ref_ids ||= []
    point_destinations = ref_ids.map{ |rid| @graph.find_index{ |e| e.ref_id == rid}}.reject(&:nil?)
    return if point_destinations.blank?
    @connections[point] += point_destinations
  end

  def write_graph_connections(io)
    Rails.logger.debug(@graph.inspect)

    for segment in @graph do
      store_connections(segment.points.first, segment.neighbours[:start])
      store_connections(segment.points.last, segment.neighbours[:end])
    end

    Rails.logger.debug(@connections.inspect)

    io.write( [@connections.size].pack("N") )
    @connections.each_pair do |point, destinations|
      next if destinations.blank?
      io.write [@vertices.find_index(point), @connections[point].size].pack("NN")
      io.write destinations.pack("N*")
    end
  end

  def check_routes_for_missing_segments
    for route in @prerouting
      prev_seg_ref_id = nil
      prev_seg_direction = nil
      i = 0
      
      while i < route.path.length
        walked_segment = route.path[i]
        direction_flag = (walked_segment[0].to_i-1) << 31
        seg_id = @graph.find_index{ |s| s.ref_id == walked_segment[1]}

        if seg_id.nil?
          prev_seg = @graph.detect{ |s| s.ref_id == prev_seg_ref_id}
          i += 1

          prev_seg_points = nil
          next_seg_points = nil

          if route.path[i].nil? # are we at the end segment of the route
            puts "route.to - #{route.to.inspect}"
            next_seg_points = [route.to]
            next_seg_ref_id = [-1]
          else
            next_seg_direction = route.path[i][0]
            next_seg_ref_id = route.path[i][1]

            next_seg = @graph.detect{ |s| s.ref_id == next_seg_ref_id}

            while next_seg.nil?
              i += 1
              if route.path[i].nil? # are we at the end segment of the route
                puts "route.to - #{route.to.inspect}"
                next_seg_points = [route.to]
                next_seg_ref_id = [-1]
                break
              else
                next_seg_direction = route.path[i][0]
                next_seg = @graph.detect{ |s| s.ref_id == route.path[i][1]}
                next_seg_ref_id = route.path[i][1]
              end
            end
          end

          next_seg_points = next_seg.points if next_seg_points.nil? && !next_seg.nil?

          missing_segment = {}
          missing_segment['id'] = walked_segment[1]
          missing_segment_direction = walked_segment[0]
          missing_segment['shape'] = {}
          missing_segment['neighbours'] = {}
          missing_segment['neighbours']['start'] = {}
          missing_segment['neighbours']['end']   = {}
          missing_segment['neighbours']['start']['segment_ref'] = prev_seg_ref_id
          missing_segment['neighbours']['end']['segment_ref'] = next_seg_ref_id

          if prev_seg_direction == "1" # normal order of points in segment (from start to end)
            if next_seg_direction == "1"
              if direction_flag == 0
                missing_segment['shape']['point'] = [prev_seg.points.last.clone, next_seg_points.first.clone]
              else
                missing_segment['shape']['point'] = [next_seg_points.first.clone, prev_seg.points.last.clone]
              end
              missing_segment['length'] = prev_seg.points.last.distance_to(next_seg_points.first)
            else
              if direction_flag == 0
                missing_segment['shape']['point'] = [prev_seg.points.last.clone, next_seg_points.last.clone]
              else
                missing_segment['shape']['point'] = [next_seg_points.last.clone, prev_seg.points.last.clone]
              end
              missing_segment['length'] = prev_seg.points.last.distance_to(next_seg_points.last)
            end
          else
            if next_seg_direction == "2"
              if direction_flag == 0
                missing_segment['shape']['point'] = [prev_seg.points.first.clone, next_seg_points.last.clone]
              else
                missing_segment['shape']['point'] = [next_seg_points.last.clone, prev_seg.points.first.clone]
              end
              missing_segment['length'] = prev_seg.points.first.distance_to(next_seg_points.last)
            else                
              if direction_flag == 0
                missing_segment['shape']['point'] = [prev_seg.points.first.clone, next_seg_points.first.clone]
              else
                missing_segment['shape']['point'] = [next_seg_points.first.clone, prev_seg.points.first.clone]
              end
              missing_segment['length'] = prev_seg.points.first.distance_to(next_seg_points.first)
            end
          end
          
          seg = ::Geometry::Segment.new(missing_segment)
          add_segment(seg)
          next
        end
        prev_seg_ref_id = walked_segment[1]
        prev_seg_direction = walked_segment[0]
        i += 1
      end
    end
  end

  def write_prerouting(io)
    io.write [@prerouting.size].pack("N")
    k = 0
    modified_segments = []

    for route in @prerouting
      write_vertex(io, route.from)
      write_vertex(io, route.to)
      #io.write [route.path.size].pack("N")
      packed_directions = route.path.each_with_index.map do |walked_segment, i|
        direction_flag = (walked_segment[0].to_i-1) << 31
        seg_id = @graph.find_index{ |s| s.ref_id == walked_segment[1]}
        next if seg_id.nil?
        seg_id.to_i | direction_flag
      end.compact

      io.write [packed_directions.size].pack("N")
      io.write packed_directions.pack("N*")
    end
  end

  def write_tileset(pack, tileset, basedir)
    dest_dir = File.join(basedir, tileset.zoom.to_s)
    tileset.tiles.each_with_index do |tile, tile_idx|
      pack.add_map_file(File.join(dest_dir, "#{tile_idx}.png"), tile.png_data)
    end
  end

  def generate_map_xml(bbox, tilesets, city_bbox, tileset_for_overall_city)
    returning(map_xml = "") do
      xml = Builder::XmlMarkup.new(:target => map_xml)
      xml.instruct!
      xml.map do |map|
        map.platform_id(@platform_id)
        map.route(:src => "routes/routing.bin", :preroute => 'routes/prerouting.bin')
        map.bbox(:north => bbox.nw.lat, :west => bbox.nw.lng, :south => bbox.se.lat, :east => bbox.se.lng)
        map.levels(:count => tilesets.size) do |levels|
          tilesets.each_pair do |zoom_level, ts|
            levels.level(:rows => ts.rows, :cols => ts.cols, :dir => "tiles/#{zoom_level}",
                         :zoom => zoom_level, :top => ts.top, :left => ts.left,
                         :size => Cloudmade::TILE_SIZE)
          end
        end
        map.city(:west => city_bbox.nw.lng, :south => city_bbox.se.lat, :east => city_bbox.se.lng, :north => city_bbox.nw.lat) do |city|
          city.level(:zoom => tileset_for_overall_city.zoom, :top => tileset_for_overall_city.top, :cols => tileset_for_overall_city.cols, :left => tileset_for_overall_city.left, :rows => tileset_for_overall_city.rows, :size => Cloudmade::TILE_SIZE, :dir => "tiles/city_tiles")
        end
      end
    end
  end

  def generate_tour_xml(tour, city_bbox)
    returning tour_xml="" do
      xml = Builder::XmlMarkup.new(:target => tour_xml)
      xml.instruct!
      xml.tour(
        :country            => tour.country,
        :city               => tour.city,
        :name               => tour.name,
        :tourID             => tour.id,
        :info               => tour.info,
        :length_in_km       => tour.length_in_km,
        :length_in_minutes  => tour.length_in_minutes,
        :city_nw_lat        => city_bbox.nw.lat,
        :city_nw_lng        => city_bbox.nw.lng,
        :city_se_lat        => city_bbox.se.lat,
        :city_se_lng        => city_bbox.se.lng,
        :platform_id        => @platform_id
      ) do |tour_xml|
        
        tour_xml.overview tour.overview
        tour_xml.tag!('LOIs') do |lois|
          tour.locations.each do |location|
            generate_location_xml(lois, location)
          end
        end
      end
    end
  end

  def generate_location_xml(xml, location)
    xml.location(:name => location.name, :longitude => location.lng, :latitude => location.lat,
                 :address => location.address, :cost => location.entrance_fee,
                 :closestPublicTransport => location.nearest_transport,
                 :shortDescription => location.short_description,
                 :iconUrl => location.s3_icon_url,
                 :icon => "icons/#{location.original_thumbnail}") do
      xml.categories do 
        location.categories.each do |c|
          xml.category :name => c.name
        end
      end
      xml.description location.full_description
      xml.contacts do
        xml.contact(:type => :url, :value => location.website) unless location.website.blank?
        xml.contact(:type => :phone, :value => location.phone) unless location.phone.blank?
        xml.contact(:type => :email, :value => location.email) unless location.email.blank?
        xml.contact(:type => :address, :value => location.address) unless location.address.blank?
      end

      xml.media do
        location.media.each do |medium|
          xml.medium('content-type' => medium.attachment.content_type,
                           'description' => medium.name,
                           'url' => 'media/'+medium.attachment.original_filename,
                           'credits' => medium.credits
                    )
        end
      end

      xml.tag!('WorkingHours', location.opening_hours)
    end
  end
end
