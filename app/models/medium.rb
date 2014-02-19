class Medium < ActiveRecord::Base
  
  self.include_root_in_json = false

  has_many :location_media, :dependent => :destroy
  has_many :locations, :through => :location_media

  belongs_to :user

  acts_as_taggable

  validates_presence_of :name, :country
  validates_uniqueness_of :attachment_fingerprint, :message => "This file was already uploaded", :full_message => "This file was already uploaded", :scope => [:user_id]

  validate do |rec|
    rec.errors.add_to_base("Unknown media type") if rec.class == Medium
  end

  named_scope :of_type, lambda {|type| { :conditions => { :type => type }} }
  named_scope :videos, :conditions => { :type => "Video" }
  named_scope :pictures, :conditions => { :type => "Picture" }
  named_scope :text_pages, :conditions => { :type => "TextPage" }
  named_scope :audios, :conditions => { :type => "Audio" }

  named_scope :in_country, lambda { |country| {:conditions => { :country => country } }}
  named_scope :in_city, lambda {|city| {:conditions => { :city => city } }}

  named_scope :all_media, :order => [ "created_at DESC" ]

  after_save :update_associated_locations
  after_destroy :update_associated_locations

  # Dummy reader allowing Location#accepts_nested_attributes_for to work.
  attr_reader :_add_to_loi

  def self.search(token)
    find(:all, :conditions => ["name LIKE :token", {:token => "#{token}%"}])
  end

  def self.build_from_params(params)
    attach = params[:attachment]

    return Medium.new(params) if attach.blank?

    content_type = if attach.content_type.class == MIME::Type
      attach.content_type.content_type
    elsif attach.content_type.class == String
      attach.content_type
    end

    klass = case content_type
    when /text\/plain/; TextPage
    when /(video|application\/mp4)/; Video
    when /image/; Picture
    when /audio/; Audio
    else
      Medium
    end

    klass.new(params)
  end

  # o_O never patch to_json in this way
  #
  def to_json(options = {})
    if options[:use_standard]
      super(options)
    else
      p "Options nil"
      helper = Object.new.extend(ActionView::Helpers::NumberHelper)
      [self.id, self.class.to_s.downcase, self.name,
       self.attachment_file_name, helper.number_to_human_size(self.attachment_file_size), self.attachment.url, self.attachment_file_size, self.tag_list, self.credits].to_json
    end
  end
  def human_size
    Object.new.extend(ActionView::Helpers::NumberHelper).number_to_human_size(self.attachment_file_size)
  end
  
  def attachment_url
    self.attachment.url
  end
  
  def attachment_type
    self.class.to_s.downcase
  end
  
  def deletable?
    locations.empty?
  end

  protected

  def update_associated_locations
    self.locations.each(&:touch)
  end

end
