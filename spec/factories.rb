require 'tempfile'

Factory.define :user do |u|
  u.name { Faker::Name.name }
  u.email { Faker::Internet.email }
  u.password "password"
  u.password_confirmation "password"
end

Factory.define :location do |l|
  l.lat { rand*0.1 }
  l.lng { rand*0.1 }
  l.name { Faker::Address.street_address }
  l.city { Faker::Address.city }
  l.country { Faker::Address.uk_country }
  l.comment { Faker::Lorem.sentence }
  l.short_description { Faker::Lorem.paragraph }
  l.full_description { Faker::Lorem.paragraph }
  l.thumbnail {File.new("spec/fixtures/media/pylesos.jpg")}
end


Factory.define :tour do |t|
  t.name { Faker::Lorem.sentence }
  t.city { Faker::Address.city }
  t.country { Faker::Address.uk_country }
  t.overview { Faker::Lorem.paragraph }
  t.info { Faker::Lorem.sentence }
  t.last_built_at {Time.now}
  t.length_in_minutes { (rand() * 120).to_i }
  t.length_in_km { (rand() * 10).to_i }
  t.user_id 1
end

Factory.define :dummy_package, :class => "TourPackage" do |p|
  p.tour { |t| t.association(:tour)}

  p.east { rand()*360-180 }
  p.west { rand()*360-180 }
  p.north{ rand()*180-90}
  p.south{ rand()*180-90}
end

def build_medium(file_path)
  Medium.build_from_params(:name => Faker::Lorem.sentence, :attachment => File.open(file_path))
end

def create_medium(file_path)
  returninig medium = build_medium(file_path) do
    medium.save
  end
end
  
