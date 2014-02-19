Then /^I should see location "([^\"]+)"$/ do |ll|
  Then "I should see \"#{ll}\" within \"span.geo\""
end
