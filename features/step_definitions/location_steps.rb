Given /^the following locations:$/ do |locations|
  Location.create!(locations.hashes)
end

When /^I delete #{capture_model}$/ do |pos|
  visit location_url(model(pos))
  click_button "Delete"
end

Then /^I should see the following locations:$/ do |expected_locations_table|
  expected_locations_table.diff!(tableish('table tr', 'td,th'))
end
