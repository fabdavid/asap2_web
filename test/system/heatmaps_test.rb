require "application_system_test_case"

class HeatmapsTest < ApplicationSystemTestCase
  setup do
    @heatmap = heatmaps(:one)
  end

  test "visiting the index" do
    visit heatmaps_url
    assert_selector "h1", text: "Heatmaps"
  end

  test "creating a Heatmap" do
    visit heatmaps_url
    click_on "New Heatmap"

    click_on "Create Heatmap"

    assert_text "Heatmap was successfully created"
    click_on "Back"
  end

  test "updating a Heatmap" do
    visit heatmaps_url
    click_on "Edit", match: :first

    click_on "Update Heatmap"

    assert_text "Heatmap was successfully updated"
    click_on "Back"
  end

  test "destroying a Heatmap" do
    visit heatmaps_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Heatmap was successfully destroyed"
  end
end
