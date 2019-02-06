require "application_system_test_case"

class CellFilteringsTest < ApplicationSystemTestCase
  setup do
    @cell_filtering = cell_filterings(:one)
  end

  test "visiting the index" do
    visit cell_filterings_url
    assert_selector "h1", text: "Cell Filterings"
  end

  test "creating a Cell filtering" do
    visit cell_filterings_url
    click_on "New Cell Filtering"

    click_on "Create Cell filtering"

    assert_text "Cell filtering was successfully created"
    click_on "Back"
  end

  test "updating a Cell filtering" do
    visit cell_filterings_url
    click_on "Edit", match: :first

    click_on "Update Cell filtering"

    assert_text "Cell filtering was successfully updated"
    click_on "Back"
  end

  test "destroying a Cell filtering" do
    visit cell_filterings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cell filtering was successfully destroyed"
  end
end
