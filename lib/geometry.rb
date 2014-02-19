module Geometry
  LatLng = Struct.new(:lat, :lng)
  BBox = Struct.new(:se, :nw)
  Segment = Struct.new(:ref_id, :length, :points)
  Route = Struct.new(:from, :to, :path)
  class LatLng
    def initialize(*args)
      lat, lng = case
      when args.size == 2:
        [args[0], args[1]]
      when args[0].is_a?(Hash) :
        [args[0]['lat'], args[0]['lng']]
      when args[0].respond_to?(:lat) :
        [args[0].lat, args[0].lng]
      else
        raise ArgumentError
      end

      super(lat.to_f, lng.to_f)
    end

    def hash
      self.to_s.hash
    end

    def deg2rad(x) 
      x * Math::PI / 180.0
    end

    def rad2deg(x)
      x * 180.0 / Math::PI
    end

    def distance_to(point)
      #Math.sqrt(((self.lat.abs - other.lat.abs).abs)**2 + ((self.lng.abs - other.lng.abs).abs)**2)
   
      r = 6371 # km
      dLat = deg2rad(self.lat - point.lat)
      dLon = deg2rad(self.lng - point.lng)
      lat1 = deg2rad(point.lat)
      lat2 = deg2rad(self.lat)
                
      sindLat2 = Math.sin(dLat/2)
      sindLon2 = Math.sin(dLon/2)
                
      a = sindLat2 * sindLat2 + sindLon2 * sindLon2 * Math.cos(lat1) * Math.cos(lat2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      r * c * 1000
    end

    def tilenum(zoom_level)
      lat_rad =  (self.lat * Math::PI / 180)
      n = 2 ** zoom_level
      xtile = ((lng + 180) / 360 * n).to_i
      ytile = ((1.0 - Math.log(Math.tan(lat_rad) + (1.0 / Math.cos(lat_rad))) / Math::PI) / 2.0 * n).to_i
      [xtile, ytile]
    end

    def to_s
      "#{self.lat}, #{self.lng}"
    end

    MAX_LATITUDE = 85.0511287798
    DEG_TO_RAD = Math::PI / 180.0
    
    # kindly taken from https://github.com/CloudMade/Leaflet/blob/master/src/geo/LatLng.js [with Vladimir Agafonkin permission]
    def to_xy(zoom)
      scale = 256 * (2**zoom)
	    lat = [[MAX_LATITUDE, self.lat].min, -MAX_LATITUDE].max
	    x = self.lng * DEG_TO_RAD
	    y = self.lat * DEG_TO_RAD
	    y = Math.log(Math.tan(Math::PI/4.0 + y/2))

      x = (x * 0.5 / Math::PI + 0.5) * scale
      y = (y * -0.5 / Math::PI + 0.5) * scale
	    {'x' => x, 'y' => y}
    end
  end

  class BBox
    def enlarge!(options = {})
      self.se = LatLng.new(self.se.lat - options[:padding].to_f, self.se.lng + options[:padding].to_f)
      self.nw = LatLng.new(self.nw.lat + options[:padding].to_f, self.nw.lng - options[:padding].to_f)
      self
    end

    def center
      max_lat = [self.se.lat, self.nw.lat].max
      min_lat = [self.se.lat, self.nw.lat].min

      max_lng = [self.se.lng, self.nw.lng].max
      min_lng = [self.se.lng, self.nw.lng].min

      center_lat = min_lat + ((max_lat - min_lat) / 2.0)
      center_lng = min_lng + ((max_lng - min_lng) / 2.0)
      LatLng.new(center_lat, center_lng)
    end
  end

  class Segment
    attr_reader :neighbours

    def initialize(desc)
      super(desc['id'], desc['length'], desc['shape']['point'].map{ |p| LatLng.new(p)})
      @neighbours = { :start => [], :end => []}
      n = desc['neighbours']

      if n
        @neighbours[:start] = n['start']['segment_ref'] if n['start']
        @neighbours[:end] = n['end']['segment_ref'] if n['end']
      end
    end
    
    def ==(other)
      self.ref_id == other.ref_id
    end
  end

end
