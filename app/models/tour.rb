class Tour < ActiveRecord::Base
  validates_presence_of :name, :overview, :info, :length_in_minutes, :length_in_km
  validates_presence_of :city, :country, :if => Proc.new {|tour| !tour.is_ubertour}
  validates_numericality_of :length_in_minutes, :length_in_km

  has_attached_file :thumbnail

  has_many :tour_locations, :dependent => :destroy

  has_many :locations, :through => :tour_locations, :order => "tour_locations.position asc"
  belongs_to :user

  accepts_nested_attributes_for :tour_locations, :allow_destroy => true

  validates_each :locations do |r,a,v|
    if (!r.is_ubertour) && (r.tour_locations.reject{ |tl| tl.marked_for_destruction? }.size < 1)
      r.errors.add_to_base('Tour must have at least one location')
    end
  end

  has_many :builds, :class_name => "TourPackage", :order => "updated_at desc"

  has_many :tour_ubertours, :foreign_key => "ubertour_id"#, :dependent => :destroy
  has_many :children, :through => :tour_ubertours, :source => :tour, :order => "position ASC"

  default_scope :order => "name asc, created_at asc"

  # (DF-654) "London" city is not displayed in places.xml for client
  # L22 in lib/places_updater.rb: tours_in_city = Tour.in_country(country).in_city(city).published
  # so we don't need any tours when city is blank
  named_scope :in_city, lambda{ |c| c.blank? ? {} : {:conditions => ['BINARY city = ?', c]} }
  named_scope :in_city_strict, lambda{ |c| {:conditions => ['BINARY city = ?', c]} }

  named_scope :in_country, lambda{ |c| {:conditions => ['BINARY country = ?', c]} }
  named_scope :by_user, lambda{ |user| {:conditions => ['user_id = ?', user.id]} }
  named_scope :country_cities, { :select => "city, country", :group => "country, city", :order => "country asc, city asc"}
  named_scope :ubertours, {:conditions => {:is_ubertour => true}}
  named_scope :regular_tours, {:conditions => {:is_ubertour => false}}

  named_scope :by_category, lambda { |category|
    {
      :joins => { :locations => { :taggings => :tag } },
      :conditions => ["tags.name = ?", category],
      :group => 'tours.id'
    }
  }

  include AASM

  aasm_state :draft
  aasm_state :building, :enter => :schedule_build!
  aasm_state :published, :enter => [:update_last_built_at, :update_places]
  aasm_state :failed
  aasm_state :edited

  aasm_initial_state :draft

  aasm_event :build do
    transitions :from => [:edited, :draft, :failed, :published], :to => :building
  end

  aasm_event :build_failed do
    transitions :from => :building, :to => :failed
  end

  aasm_event :edit do
    transitions :to => :edited, :from => [:failed, :published]
  end

  aasm_event :publish do
    transitions :from => [:draft, :failed, :building, :published], :to => :published
  end

  def categories
    locations.all(:joins => :categories).map{ |l| l.category_list }.flatten.uniq
  end

  after_save :set_edited_after_save

  def set_edited_after_save
    edit! if published? || failed?
  end

  def bbox
    if self.is_ubertour
      return @ubertour_bbox if defined?(@ubertour_bbox)
      locs = self.children.collect{|tour| tour.locations }.flatten
      locs_lats = locs.collect{|l| l.lat}
      locs_lngs = locs.collect{|l| l.lng}
      se_lat = locs_lats.min
      se_lng = locs_lngs.max
      nw_lat = locs_lats.max
      nw_lng = locs_lngs.min
      @ubertour_bbox = ::Geometry::BBox.new(Geometry::LatLng.new(se_lat, se_lng), Geometry::LatLng.new(nw_lat, nw_lng))
      @ubertour_bbox
    else
      return @tour_bbox if defined?(@tour_bbox)
      return nil if self.locations.empty?
      locs = self.locations
      se = locs.first.latlng
      nw = locs.first.latlng

      locs.each do |l|
        se.lat = [l.lat, se.lat].min
        se.lng = [l.lng, se.lng].max
        nw.lat = [l.lat, nw.lat].max
        nw.lng = [l.lng, nw.lng].min
      end
      @tour_bbox = ::Geometry::BBox.new(se, nw)
      @tour_bbox.enlarge!(:padding => BBOX_PADDING) if locs.size == 1
      @tour_bbox
    end
  end

  def center
    self.bbox.center
  end

  def overall_ubertour_bbox(ubertour_routing_bbox)
    # self.bbox AND ubertour_routing_bbox
    locs = [ubertour_routing_bbox.se, ubertour_routing_bbox.nw, self.bbox.se, self.bbox.nw]
    locs_lats = locs.collect{|l| l.lat}
    locs_lngs = locs.collect{|l| l.lng}
    se_lat = locs_lats.min
    se_lng = locs_lngs.max
    nw_lat = locs_lats.max
    nw_lng = locs_lngs.min
    ::Geometry::BBox.new(Geometry::LatLng.new(se_lat, se_lng), Geometry::LatLng.new(nw_lat, nw_lng))
  end

  def self.get_city_bbox(country_name, city_name)
    city_country_to_geocode = "country:#{country_name}"
    city_country_to_geocode += ";city:#{city_name}" if !city_name.blank?
    Rails.logger.warn 'city_country_to_geocode - ' + city_country_to_geocode.inspect
    url = "http://geocoding.cloudmade.com/#{CLOUDMADE_API_KEY}/geocoding/v2/find.js?query=#{city_country_to_geocode}"
    Rails.logger.warn 'URI.encode(url) - ' + URI.encode(url).inspect
    begin
      response = Net::HTTP.get_response(URI.parse(URI.encode(url)))
      response = case response
        when Net::HTTPSuccess
          json = JSON.parse(response.body)
          if ! json['bounds'].blank?
            city_bbox = Geometry::BBox.new( Geometry::LatLng.new(json['bounds'][0][0], json['bounds'][1][1]),
                       Geometry::LatLng.new(json['bounds'][1][0], json['bounds'][0][1]) )
            Rails.logger.warn 'Retrieved city bbox - ' + city_bbox.inspect
            return city_bbox
          end
        else
          Rails.logger.warn 'Check city/country for your tour! ' + response.inspect
      end
    rescue Net::HTTPBadResponse => e
      Rails.logger.warn "An error occured: #{e.message}\n"
    rescue Timeout::Error => e
      Rails.logger.warn "Timeout error for #{url}\n"
    rescue => e
      Rails.logger.warn "An error occured: #{e.message}\n"
    end
  end

  def location_coords
    tour_locations.all(:joins => :location).map{ |tl| tl.location.latlng }
  end

  def schedule_build!
    return false unless valid?
    self.build_message = 'Build scheduled'
    #self.build_job = Delayed::Job.enqueue TourBuilderJob.new(self.id)
    Resque.enqueue TourBuilderJob, self.id
    self.save
  end

  def build_in_progress?
    build_job and !build_job.failed?
  end

  def obsolete?
    return true if builds.empty?
    updates = [self.updated_at]+locations.map{|l| [l.updated_at, l.media.map(&:updated_at)]}.flatten
    updates.any?{|upd| upd >= last_built_at}
  end

  def update_last_built_at
    self.update_attribute(:last_built_at, 1.seconds.from_now)
  end

  def area_too_big?
    area_bbox = bbox
    return false unless area_bbox
    [area_bbox.se.lng-area_bbox.nw.lng, area_bbox.nw.lat-area_bbox.se.lat].any?{|diff| diff > 0.1}
  end
  
  def deletable?
    self.builds.empty? && !self.building?
  end
  
  def update_places
    Resque.enqueue PlacesUpdater
  end

  def build_ubertour!(platform_id = PLATFORMS::IPHONE3)
    return if ! self.is_ubertour

    [PLATFORMS::IPHONE3, PLATFORMS::IPHONE4].each do |platform_id|
      package = TourPackage.new(:tour => self, :tour_name => self.name, :country => self.country, :city => self.city, :platform_id => platform_id, :south => self.bbox.se.lat, :east => self.bbox.se.lng, :north => self.bbox.nw.lat, :west => self.bbox.nw.lng)

      tileset_for_overall_city = package.add_overall_tour_map(self.bbox, :platform_id => platform_id)
      #map_xml = generate_map_xml(package.bbox, @tileset, city_bbox, tileset_for_overall_city)
      #package.add_map_file(package.map_xml_name, map_xml)

      ubertour_xml = generate_ubertour_xml(platform_id)
      package.add_file(package.tour_xml_name, ubertour_xml)
      package.save!
    end
  end

  def generate_ubertour_xml(platform_id)
    returning tour_xml="" do
      xml = Builder::XmlMarkup.new(:target => tour_xml)
      xml.instruct!
      xml.ubertour(
        :country            => self.country,
        :city               => self.city,
        :name               => self.name,
        :ubertour_id        => self.id,
        :info               => self.info,
        :length_in_km       => self.length_in_km,
        :length_in_minutes  => self.length_in_minutes,
        :nw_lat             => self.bbox.nw.lat,
        :nw_lng             => self.bbox.nw.lng,
        :se_lat             => self.bbox.se.lat,
        :se_lng             => self.bbox.se.lng,
        :platform_id        => platform_id
      ) do |tour_xml|
        tour_xml.overview self.overview
        tour_xml.tag!('tours') do |tours|
          self.children.each_with_index do |tour, index|
            tour_builds = tour.builds.sort{|m,n| m.created_at <=> n.created_at}
            iphone3_build = tour_builds.size > 1 ? tour_builds[-2] : tour_builds.last # temporary measure
            iphone4_build = tour_builds.size > 1 ? tour_builds[-1] : tour_builds.last
            build = case platform_id
              when PLATFORMS::IPHONE3; iphone3_build
              when PLATFORMS::IPHONE4; iphone4_build
            end
            tours.tag!('tour', :xml_url => build.tour_xml_s3_url, :nw_lat => tour.bbox.nw.lat, :nw_lng => tour.bbox.nw.lng, :se_lat => tour.bbox.se.lat, :se_lng => tour.bbox.se.lng, :locations_count => tour.locations.count, :name => tour.name, :length_in_km => tour.length_in_km, :length_in_minutes => tour.length_in_minutes, :id => tour.id, :build_id => build.id)
          end
        end
      end
    end
  end
end
