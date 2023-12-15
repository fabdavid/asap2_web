require "application_system_test_case"

class CellSetsTest < ApplicationSystemTestCase
  setup do
    @cell_set = cell_sets(:one)
  end

  test "visiting the index" do
    visit cell_sets_url
    assert_selector "h1", text: "Cell Sets"
  end

  test "creating a Cell set" do
    visit cell_sets_url
    click_on "New Cell Set"

    click_on "Create Cell set"

    assert_text "Cell set was successfully created"
    click_on "Back"
  end

  test "updating a Cell set" do
    visit cell_sets_url
    click_on "Edit", match: :first

    click_on "Update Cell set"

    assert_text "Cell set was successfully updated"
    click_on "Back"
  end

  test "destroying a Cell set" do
    visit cell_sets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cell set was successfully destroyed"
  end
end
