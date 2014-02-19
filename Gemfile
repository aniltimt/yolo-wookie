source "http://rubygems.org"

#gem "sqlite3", "~> 0.1.1" ,:group => :development
# Passenger's automation messes gem loading up, so we have to include bundler in Gemfile
gem 'bundler'
gem "rails", "2.3.14"

gem 'geokit'
gem 'haml'
gem 'inherited_resources', '1.0.4'
gem 'has_scope'
gem 'responders'
gem 'acts_as_list', '= 0.1.5'
gem 'aasm'

gem 'httparty'
gem 'tzinfo'
gem 'ruby-debug'
gem 'mysql'
gem 'paperclip', '~> 2.3' # shitty gem :)
gem 'carrierwave', '~> 0.4' #:git => 'https://github.com/jnicklas/carrierwave.git', :branch => '0.4-stable'
gem 'rmagick', '= 2.5.1'
gem 'capistrano'

gem 'aws-s3', :require => "aws/s3"
gem 'amazon-ec2', :require => "AWS"
gem 'will_paginate'
gem 'devise', '1.0.9'
gem "multi_xml"
gem 'redis', '= 2.2.0'
gem 'resque', '~> 1.19' #:git => "git://github.com/defunkt/resque.git" # -r option for resque-web is on the edge version
gem 'resque-scheduler', '= 1.9.9'
gem "SystemTimer", "~> 1.2.3" # for redis
gem 'whenever', :require => false
gem 'jrails'
gem 'nokogiri'

group :test, :cucumber do
  gem "rcov"
  gem "factory_girl"
  gem "spork"
  gem "faker", '= 0.3.1'
  gem "rspec", '= 1.3.2'
  gem "rspec-rails", '= 1.3.4'
  gem "webrat", '= 0.7.3'
  gem "pickle"
  gem "database_cleaner"
  gem "ZenTest"
  gem "autotest"
  gem "autotest-rails"
end
