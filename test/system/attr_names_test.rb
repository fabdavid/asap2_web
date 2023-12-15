require "application_system_test_case"

class AttrNamesTest < ApplicationSystemTestCase
  setup do
    @attr_name = attr_names(:one)
  end

  test "visiting the index" do
    visit attr_names_url
    assert_selector "h1", text: "Attr Names"
  end

  test "creating a Attr name" do
    visit attr_names_url
    click_on "New Attr Name"

    click_on "Create Attr name"

    assert_text "Attr name was successfully created"
    click_on "Back"
  end

  test "updating a Attr name" do
    visit attr_names_url
    click_on "Edit", match: :first

    click_on "Update Attr name"

    assert_text "Attr name was successfully updated"
    click_on "Back"
  end

  test "destroying a Attr name" do
    visit attr_names_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Attr name was successfully destroyed"
  end
end
