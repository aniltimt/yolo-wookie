class TourPackage < ActiveRecord::Base
  acts_as_taggable_on :categories

  belongs_to :tour

  before_create :copy_data_from_tour
  after_save :write_changes, :compress_package
  after_destroy :clear_files

  attr_accessor :save_with_build_id

  def bbox=(bbox)
    self.south = bbox.se.lat
    self.east = bbox.se.lng
    self.north = bbox.nw.lat
    self.west = bbox.nw.lng
    bbox(true)
  end

  def bbox(reload=false)
    @bbox = nil if reload
    @bbox ||= ::Geometry::BBox.new(::Geometry::LatLng.new(self.south, self.east),
                                   ::Geometry::LatLng.new(self.north, self.west))
  end

  def self.root
    File.join(Rails.public_path, 'builds')
  end

  def build_root
    File.join(TourPackage.root, self.id.to_s)
  end

  def content_root
    @content_root ||= File.join(build_root, 'content')
  end

  def ubertour_routing_xml_name
    File.join('map', 'routes', 'ubertour_routing.xml')
  end

  def tour_xml_name
    #"#{tour.name.downcase.underscore}.xml"
    "tour.xml"
  end

  def tour_xml_path
    File.join(content_root, tour_xml_name)
  end
 
  def tour_xml_s3_uri
    # COUNTRY/CITY/TOUR_ID/TOUR_BUILD_ID.xml
    "#{self.tour.country}/#{self.tour.city}/#{self.tour.id}/#{self.platform_id}/#{@save_with_build_id || self.id}.xml"
  end

  def tour_xml_s3_url
    S3_URL + "#{current_s3_bucket}/#{tour_xml_s3_uri}"
  end

  def map_xml_name
    'map.xml'
  end

  def map_xml_path
    File.join(content_root, map_xml_name)
  end

  def map_pack_path
    File.join(build_root, "map.pack")
  end

  def tour_pack_path
    File.join(build_root, "tour.pack")
  end

  def tour_pack_s3_uri
    # COUNTRY/CITY/TOUR_ID/PLATFORM_ID/TOUR_BUILD_ID.pack (it's platform specific since could contain maps with different resolutions for different platforms)
    "#{self.tour.country}/#{self.tour.city}/#{self.tour.id}/#{self.platform_id}/#{@save_with_build_id || self.id}.pack"
  end

  def tour_pack_s3_url
    S3_URL + "#{current_s3_bucket}/#{tour_pack_s3_uri}"
  end

  def add_file(name, data)
    @new_files ||= { }
    @new_files[name] = data
  end

  def add_map_file(name, data)
    add_file(File.join('map', name), data)
  end

  def add_tour_file(name, data)
    add_file(File.join('tour'), data)
  end

  def contents
    @contents ||= Dir["#{content_root}/**/**"]
  end

  def current_s3_bucket
    S3_BUCKET_NAME
  end

  def destroy_s3_files
    TourPackage.initialize_s3

    self.tour.locations.each do |location|
      AWS::S3::S3Object.delete(location.s3_icon_uri, current_s3_bucket) if AWS::S3::S3Object.exists?(location.s3_icon_uri, current_s3_bucket)
    end
    AWS::S3::S3Object.delete(tour_pack_s3_uri, current_s3_bucket) if AWS::S3::S3Object.exists?(tour_pack_s3_uri, current_s3_bucket)
    AWS::S3::S3Object.delete(tour_xml_s3_uri, current_s3_bucket) if AWS::S3::S3Object.exists?(tour_xml_s3_uri, current_s3_bucket)
  end

  def add_overall_tour_map(city_or_ubertour_bbox, options = {})
    city_tiles_loader = case options[:platform_id]
      when PLATFORMS::IPHONE4
        TileLoader.new(CLOUDMADE_API_KEY, :load_hires_tiles => true) 
      when PLATFORMS::IPHONE3
        TileLoader.new(CLOUDMADE_API_KEY)      
    end

    tiles_in_city_side = case options[:platform_id]
      when PLATFORMS::IPHONE4; 6
      when PLATFORMS::IPHONE3; 3
    end

    folder_for_tiles = if options[:tour_id]
      tour = Tour.find options[:tour_id]
      if tour.is_ubertour
        'ubertours_tiles'
      else
        'city_tiles'
      end
    else
      'city_tiles'
    end

    current_zoom = 3
    
    current_zoom.upto(15) do |zoom|
      test_tileset = TileLoader::Tileset.new(city_or_ubertour_bbox, zoom)
      Rails.logger.warn "testing zoom level #{zoom} with #{test_tileset.y_tiles_count} y_tiles and #{test_tileset.x_tiles_count} x_tiles"
      # tiles_in_city_side*tiles_in_city_side = 9|36 tiles we need
      if test_tileset.x_tiles_count >= tiles_in_city_side && test_tileset.y_tiles_count >= tiles_in_city_side
        current_zoom = zoom
        break
      end
    end

    tileset = city_tiles_loader.get_area_tileset(city_or_ubertour_bbox, current_zoom)
    tileset.tiles.each_with_index do |tile, tile_idx|
      self.add_map_file(File.join('tiles', folder_for_tiles, "#{tile_idx}.png"), tile.png_data)
    end
    tileset
  end

  def add_pobs_to_tour
    require 'net/http'
    require 'uri'

    south = self.tour.bbox.se.lat.to_f - POBS_BBOX_PADDING
    east = self.tour.bbox.se.lng.to_f + POBS_BBOX_PADDING
    north = self.tour.bbox.nw.lat.to_f + POBS_BBOX_PADDING
    west = self.tour.bbox.nw.lng.to_f - POBS_BBOX_PADDING
    
    url = URI.parse(MARKET_API_SERVER_URL + "/pobs/create_bundle?tour_id=#{self.tour.id}&categories=#{self.tour.pob_categories_ids}&se=#{[south, east].join(',')}&nw=#{[north, west].join(',')}")
    if url.port == 443
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url.request_uri)
      response = http.request(request)
    else
      response = Net::HTTP.get_response(url)
    end

    if response.code.to_i == 403
      raise StandardError.new("failed to create bundle with POBs for Tour ##{self.tour.id}: either tour_id or south-east or north-west coordinates is empty")
    end
  end

  private

  def write_changes
    FileUtils.mkdir_p(content_root)

    @new_files ||= { }
    @new_files.each_pair do |fname, content|
      write_to_build fname, content
    end

    media_dir = FileUtils.mkdir_p(File.join(content_root, 'media'))
    icons_dir = FileUtils.mkdir_p(File.join(content_root, 'icons'))

    FileUtils.cp(tour.thumbnail.path, icons_dir) if tour.thumbnail?

    if ! tour.locations.blank?
      tour.locations(:join => :media).each do |location|
        FileUtils.cp(location.thumbnail.path, icons_dir) if location.thumbnail?
        location.media.each do |medium|
          FileUtils.cp(medium.attachment.path, media_dir) if medium.attachment.exists?
        end
      end
    end
  end

  def compress_package   
    # pack all files to one tour.pack which will be stored in s3
    all_tour_files = Dir["#{content_root}/**/**"]
    write_package_files('tour.pack', all_tour_files)

    TourPackage.initialize_s3

    push_tour_icons_to_s3 if ! self.tour.is_ubertour
    push_tour_pack_to_s3
    push_tour_xml_to_s3
  end

  def write_package_files(destination, files_list)
    files = []
    directories = []

    files_list.each do |ent|
      if File.directory?(ent)
        directories << ent
      else
        files << ent
      end
    end

    File.open(File.join(self.build_root, destination), "w") do |f|
      f << [directories.size].pack("N")
      f << directories.map{ |dir| pack_relative_path(dir)}.join
      f << [files.size].pack("N")
      files.each do |file_name|
        f << pack_relative_path(file_name)
        f << [File.size(file_name)].pack("N")
        f << File.read(file_name)
      end
    end

  end

  def pack_relative_path(str)
    str = str.gsub(content_root, '')
    [str.length, str].pack("NA#{str.length}")
  end

  def write_to_build(fname, content)
    full_path = File.expand_path(fname, content_root)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.open(full_path, "w"){ |f| f.write content}
  end

  def clear_files
    FileUtils.rm_rf(build_root) && destroy_s3_files
  end

  def copy_data_from_tour
    self.locations_count = tour.locations.count
    self.tour_name = tour.name
    self.city = tour.city
    self.country = tour.country
  end

  def self.initialize_s3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3_ACCESS_KEY,
      :secret_access_key => S3_SECRET
    )
    Rails.logger.warn 'S3_BUCKET_NAME - ' + S3_BUCKET_NAME.inspect
    if !AWS::S3::Service.buckets.collect{|bucket| bucket.name}.include?(S3_BUCKET_NAME)
      Rails.logger.warn "creating #{S3_BUCKET_NAME}"
      AWS::S3::Bucket.create(S3_BUCKET_NAME)
    end
  end

  def push_tour_icons_to_s3
    begin
      self.tour.locations.each do |location|
        if File.exists?(location.thumbnail.path)
          AWS::S3::S3Object.store(location.s3_icon_uri, open(location.thumbnail.path), current_s3_bucket)
        end
      end
    rescue Errno::ENOENT => e
      puts "there was an error while pushing location's icon to s3: #{e.message}"
    end
  end

  def push_tour_pack_to_s3
    begin
      if File.exists?(tour_pack_path)
        AWS::S3::S3Object.store(tour_pack_s3_uri, open(tour_pack_path), current_s3_bucket)
      end
    rescue Errno::ENOENT => e
      puts "there's no tour pack on local filesystem: #{e.message}"
    end
  end

  def push_tour_xml_to_s3
    begin
      if File.exists?(tour_xml_path)
        AWS::S3::S3Object.store(tour_xml_s3_uri, open(tour_xml_path), current_s3_bucket)
      end
    rescue Errno::ENOENT => e
      puts "there's no xml for tour on local filesystem: #{e.message}"
    end
  end
end
