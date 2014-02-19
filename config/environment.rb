# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  config.autoload_paths += %W( #{Rails.root}/app/sweepers )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.

  # NB: EC2 prerouting server start/stop S3 lock is based on timestamps in current timezone so in changing this
  # please consider that staging and production servers should be in one zone so ec2 server will be start/stopped properly
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

require 'lib/geometry'

CLOUDMADE_API_KEY = '0e4c31be5b0f4424996fb1790441c7a6'

S3_URL = 'http://s3.amazon.com/'
S3_ACCESS_KEY = "AKIAJBOJBDC45EBSXYAA"
S3_SECRET     = "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"

ROUTING_SERVER_ACCESS_KEY = 'AKIAJ5VCHF7EFHGKHHDQ'
ROUTING_SERVER_SECRET     = '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'
ROUTING_SERVER_INSTANCE_ID= 'i-10cbd67f'
ROUTING_SERVER_EIP = '50.19.91.53'

APPLICATION_NAME = "tour_builder"
S3_BUCKET_NAME = "#{APPLICATION_NAME}_#{Rails.env}"

module PLATFORMS
  IPHONE3 = 1 # the same for ipad?
  IPHONE4 = 2

  ANDROID = 10
end

BBOX_PADDING = 0.003

POBS_BBOX_PADDING = 0.01

TB_SYNC_LOGIN = "TB_SYNC_LKJDFRIKF"
TB_SYNC_PASSWD  = "f#ER@er12$99"

AWS::S3::Base.establish_connection!(
  :access_key_id     => S3_ACCESS_KEY,
  :secret_access_key => S3_SECRET
)

ROUTING_METHOD = :cloudmade # could be either :cloudmade or :osm
