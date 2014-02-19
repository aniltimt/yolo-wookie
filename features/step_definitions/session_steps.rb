Given /^I am logged in as #{capture_model}$/ do |name|
  user = model(name)

  Given "I am on the login page"
  Given "I fill in \"Email\" with \"#{user.email}\""
  Given "I fill in \"Password\" with \"password\""
  Given "I press \"Login\""
end
