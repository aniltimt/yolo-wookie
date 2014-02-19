Feature: Manage locations
  In order to have ability to build tours
  As a registered user
  I want to be able to manage locations of interest

  Background:
    Given a user exists
      And I am logged in as that user

  Scenario: Register new location
    Given I am on the new location page
    When I fill in "Name" with "Twickenham Stadium"
      And I fill in "Latitude" with "34.209362"
      And I fill in "Longitude" with "-85.147347"
      And I fill in "City" with "London"
      And I fill in "Country" with "UK"
      And I fill in "Full description" with "Great venue"
      And I fill in "Comment" with "Some piece of comment"
      And I press "Create"
    Then I should see "Location was successfully created"
      And I should see "Great venue"
      And I should see location "34.209362; -85.147347"
      And I should see "Twickenham Stadium"

  Scenario: Delete location
    Given 5 locations exist
      And location exist with name: "All Your Base Are Belongs To Us"
    When I delete that location
    Then location should not exist with name: "All Your Base Are Belongs To Us"
