class Location < ActiveRecord::Base
  validates_presence_of :name, :full_description, :city, :country, :comment, :unless => Proc.new { |l| l.is_draft? }
  validates_numericality_of :lat, :lng, :unless => Proc.new { |l| l.is_draft? }
  validates_uniqueness_of :comment, :scope => [:name, :user_id], :unless => Proc.new { |l| l.is_draft? }
  validate :correctness_of_categories

  has_many :location_media, :dependent => :destroy
  has_many :media, :through => :location_media

  has_many :tour_locations, :dependent => :destroy
  has_many :tours, :through => :tour_locations

  belongs_to :user

  acts_as_taggable_on :categories

  named_scope :in_city, lambda{ |city_name| { :conditions => {:city => city_name} }}
  named_scope :in_country, lambda{ |country_name| { :conditions => {:country => country_name} }}
  named_scope :country_cities, { :select => "id, city, country", :group => "country, city", :order => "country asc, city asc"}
  named_scope :by_user, lambda{ |user| {:conditions => ['user_id = ?', user.id]} }
  default_scope :order => "name asc, created_at asc"

  #has_attached_file :thumbnail, :styles => { :original => "176x176"}
  #validates_attachment_presence :thumbnail
  mount_uploader :thumbnail, ThumbnailUploader
  validates_presence_of :thumbnail, :message => 'should be uploaded', :unless => Proc.new { |l| l.is_draft? }
  
  after_save :set_related_tours_edited_after_save, :unless => Proc.new { |l| l.is_draft? }

  def set_related_tours_edited_after_save
    self.tours.each do |tour|
      tour.edit! if tour.published?
    end
  end

  def original_thumbnail
    File.basename(thumbnail.to_s)
  end

  #attr_accessor :geocode # to save geocode addess if record is not valid

  def self.category_counts_by_name
    category_counts(:order => 'name asc')
  end

  def latlng
    ::Geometry::LatLng.new(self)
  end

  def self.places
    Location.country_cities.group_by{ |l| l.country }
  end

  def thumbnail_format
    if self.thumbnail_content_type
      self.thumbnail_content_type.to_s.split('/').last
    else
      'jpeg'
    end
  end

  def s3_icon_uri
    "icon_#{self.id}_#{self.updated_at.to_i}.#{self.thumbnail_format}"
  end

  def s3_icon_url
    S3_URL + "#{S3_BUCKET_NAME}/#{s3_icon_uri}"
  end
  
  def deletable?
    tours.empty?
  end

  def is_draft?
    self.is_draft
  end

  def correctness_of_categories
    if self.category_list.empty?
      return
    end
    invalid = []
    self.category_list.each do |c|
      if LocationCategory.find_by_name(c).nil?
        invalid << c
      end
    end
    if !invalid.empty?
      errors.add(:categories, invalid.join(", ") << " are invalid")
    end
  end
end
