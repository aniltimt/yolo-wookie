require 'rubygems'
require 'spork'
require 'pp'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
  #require 'spec/autorun'
  require 'spec/rails'

  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories.
  Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

  Webrat.configure do |config|
    config.mode = :rails
  end

  Spec::Runner.configure do |config|
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  end
end

def new_medium(file_name)
  m = Medium.build_from_params(:name => Faker::Lorem.sentence, :attachment => File.open(file_name))
end

def create_medium(file_name)
  returning m = new_medium(file_name) do
    m.save!
  end
end

# stub requesting actual tiles
class TourPackage
  def add_overall_tour_map(city_bbox, options = {})
    9.times do |i|
      self.add_map_file(File.join('tiles', 'city_tiles', "#{i}.png"), File.read(Rails.root.join('spec','fixtures','10.png').to_s))
    end

    tileset = TileLoader::Tileset.new(bbox, 14, [TileLoader::Tile.new(File.open(Rails.root.join('spec', 'fixtures', '10.png').to_s).read, 54.243424, 12.444, 14)])
    tileset
  end
end
