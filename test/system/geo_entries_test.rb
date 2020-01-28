require "application_system_test_case"

class GeoEntriesTest < ApplicationSystemTestCase
  setup do
    @geo_entry = geo_entries(:one)
  end

  test "visiting the index" do
    visit geo_entries_url
    assert_selector "h1", text: "Geo Entries"
  end

  test "creating a Geo entry" do
    visit geo_entries_url
    click_on "New Geo Entry"

    click_on "Create Geo entry"

    assert_text "Geo entry was successfully created"
    click_on "Back"
  end

  test "updating a Geo entry" do
    visit geo_entries_url
    click_on "Edit", match: :first

    click_on "Update Geo entry"

    assert_text "Geo entry was successfully updated"
    click_on "Back"
  end

  test "destroying a Geo entry" do
    visit geo_entries_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Geo entry was successfully destroyed"
  end
end
