class TileLoader
  include HTTParty

  Tile = Struct.new(:png_data, :x, :y, :zoom)
  Tileset = Struct.new(:lef, :top, :rows, :cols, :zoom, :tiles)

  class Tileset
    attr_accessor :tiles
    attr_reader :bbox, :zoom, :rows, :cols, :left, :top

    def initialize(bbox, zoom, tiles=[])
      @bbox = bbox
      @zoom = zoom
      @tiles = tiles

      @nw = bbox.nw.tilenum(zoom)
      @se = bbox.se.tilenum(zoom)
      @rows = @se[1] - @nw[1] + 1
      @cols = @se[0] - @nw[0] + 1

      @left = @nw[0]*Cloudmade::TILE_SIZE
      @top = @nw[1]*Cloudmade::TILE_SIZE
    end

    def xrange
      @nw[0]..@se[0]
    end

    def yrange
      @nw[1]..@se[1]
    end

    def x_tiles_count
      xrange.count
    end

    def y_tiles_count
      yrange.count
    end

    def tiles_count
      x_tiles_count * y_tiles_count
    end
  end

  base_uri '107.20.174.7:81' #'tile.cloudmade.com'
  default_timeout 60 # initial timeout is 1 minute since tile server can generate tiles pretty long

  cattr_accessor :default_map_style
  attr_reader :api_key, :map_style, :load_hires_tiles, :tiles_retry_count

  self.default_map_style = Cloudmade::MAP_STYLE_ID

  def initialize(api_key, options = {})
    @load_hires_tiles = options[:load_hires_tiles] || false
    @loading_tile_index = 0
    @tiles_retry_count = 0

    if options[:tour_id]
      @tour = Tour.find options[:tour_id] # we need tour because we need to update it's build_message while loading tiles
    end

    @api_key = api_key
    @map_style = options[:default_map_style] || self.class.default_map_style
  end

  def get_tile(point, zoom)
    tile_x, tile_y = point.tilenum(zoom)
    get_tile_xy(tile_x, tile_y, zoom)
  end

  # Returns instance of Tile struct, initialized with tile's raw png data at given (x,y) and zoom level.
  def get_tile_xy(x, y, zoom)
    type_of_tiles = (@load_hires_tiles ? 'tiles_hires' : 'osm_tiles2')
    begin
      Tile.new(self.class.get("/#{type_of_tiles}/#{zoom}/#{x}/#{y}.png"), x, y, zoom)
    rescue Timeout::Error, EOFError # timeout or end of file reached
      if @tiles_retry_count < 60
        @tiles_retry_count += 1
        retry
      else
        @tour.build_failed! if @tour
        raise Cloudmade::TilesUnavailable
      end
    end
  end

  def tiles_count_on_all_zoom_levels(bbox)
    @tiles_count ||= (@load_hires_tiles ? Cloudmade::HIRES_TILESET_ZOOM_RANGE : Cloudmade::LOWRES_TILESET_ZOOM_RANGE).sum{|zoom_level| Tileset.new(bbox, zoom_level).tiles_count }
    @tiles_count
  end

  RAD_TO_DEG = 180.0 / Math::PI

  # from https://github.com/CloudMade/Leaflet/blob/master/src/geo/projection/Projection.Mercator.js
  # add https://github.com/CloudMade/Leaflet/blob/master/src/geometry/Transformation.js
  def to_latlng(x, y, zoom)
    a = 0.5/Math::PI
    b = 0.5
    c = -0.5/Math::PI
    d = 0.5

    #(point.x/scale - this._b) / this._a, (point.y/scale - this._d) / this._c)

    scale = 256 * (2**zoom)
	  lng = x / scale * RAD_TO_DEG
  	lat = (2 * Math.atan(Math.exp(y)) - Math::PI/2) * RAD_TO_DEG  # WHERE TO PUT SCALE?

		::Geometry::LatLng.new(lat, lng)
  end

  def enlarge_your_bbox(bbox, zoom)
    se = bbox.se
    nw = bbox.nw

    new_se = ::Geometry::LatLng.new(se.lat - 0.003, se.lng + 0.003)
    new_nw = ::Geometry::LatLng.new(nw.lat + 0.003, nw.lng - 0.003)
    new_bbox = ::Geometry::BBox.new(new_se, new_nw)
  end

  # Returns array of tiles for specified bbox at given zoom level
  def get_area_tileset(bbox, zoom)
    tileset = Tileset.new(bbox, zoom)

    for y in tileset.yrange
      for x in tileset.xrange
        @loading_tile_index += 1

        Rails.logger.debug("Loading tile at (#{x}, #{y}, #{zoom})")
        if @tour
          @tour.build_message = "Loading tile ##{@loading_tile_index} of #{tiles_count_on_all_zoom_levels(bbox)} total #{@load_hires_tiles ? 'hi' : 'low'}res tiles"
          @tour.save(false) # update w/o calling validations
        end

        tileset.tiles << get_tile_xy(x,y,zoom)
      end
    end
    tileset
  end

  # [DF-226] additional constrain to ensure that bounding box is not less than 4 tiles on smallest side in each zoom level
  def test_lowest_from_zoom_levels(bbox, zoom_range)
    # we only need to test smalest zoom since if it's < 4 tiles all other zoom levels must be shifted up as well

    Rails.logger.warn "testing zoom level #{zoom_range.first} so bbox is not less then 4 tiles on each zoom level"
    test_tileset = Tileset.new(bbox, zoom_range.first)

    if test_tileset.x_tiles_count < 2 && test_tileset.y_tiles_count < 2 # 2*2 = 4 tiles we need at least
      (zoom_range.first + 1)..(zoom_range.last + 1) # shift zoom ranges up
    else
      zoom_range
    end
  end

  # This returns array of tilesets for each zoom level defined by Cloudmade::TILESET_ZOOM_RANGE
  def get_area_levels(bbox)
    zoom_levels = if @load_hires_tiles
      Cloudmade::HIRES_TILESET_ZOOM_RANGE
    else
      Cloudmade::LOWRES_TILESET_ZOOM_RANGE
    end

    tested_zoom_levels = test_lowest_from_zoom_levels(bbox, zoom_levels)

    tested_zoom_levels.map{ |zoom_level| get_area_tileset(bbox, zoom_level)}

    #Cloudmade::TILESET_ZOOM_RANGE.map{ |zoom_level| get_area_tileset(bbox, zoom_level)}
  end
end
