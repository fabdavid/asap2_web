require "application_system_test_case"

class FilteringsTest < ApplicationSystemTestCase
  setup do
    @filtering = filterings(:one)
  end

  test "visiting the index" do
    visit filterings_url
    assert_selector "h1", text: "Filterings"
  end

  test "creating a Filtering" do
    visit filterings_url
    click_on "New Filtering"

    click_on "Create Filtering"

    assert_text "Filtering was successfully created"
    click_on "Back"
  end

  test "updating a Filtering" do
    visit filterings_url
    click_on "Edit", match: :first

    click_on "Update Filtering"

    assert_text "Filtering was successfully updated"
    click_on "Back"
  end

  test "destroying a Filtering" do
    visit filterings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Filtering was successfully destroyed"
  end
end
