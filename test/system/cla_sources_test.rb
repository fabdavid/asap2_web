require "application_system_test_case"

class ClaSourcesTest < ApplicationSystemTestCase
  setup do
    @cla_source = cla_sources(:one)
  end

  test "visiting the index" do
    visit cla_sources_url
    assert_selector "h1", text: "Cla Sources"
  end

  test "creating a Cla source" do
    visit cla_sources_url
    click_on "New Cla Source"

    click_on "Create Cla source"

    assert_text "Cla source was successfully created"
    click_on "Back"
  end

  test "updating a Cla source" do
    visit cla_sources_url
    click_on "Edit", match: :first

    click_on "Update Cla source"

    assert_text "Cla source was successfully updated"
    click_on "Back"
  end

  test "destroying a Cla source" do
    visit cla_sources_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cla source was successfully destroyed"
  end
end
