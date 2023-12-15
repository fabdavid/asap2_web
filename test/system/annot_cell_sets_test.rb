require "application_system_test_case"

class AnnotCellSetsTest < ApplicationSystemTestCase
  setup do
    @annot_cell_set = annot_cell_sets(:one)
  end

  test "visiting the index" do
    visit annot_cell_sets_url
    assert_selector "h1", text: "Annot Cell Sets"
  end

  test "creating a Annot cell set" do
    visit annot_cell_sets_url
    click_on "New Annot Cell Set"

    click_on "Create Annot cell set"

    assert_text "Annot cell set was successfully created"
    click_on "Back"
  end

  test "updating a Annot cell set" do
    visit annot_cell_sets_url
    click_on "Edit", match: :first

    click_on "Update Annot cell set"

    assert_text "Annot cell set was successfully updated"
    click_on "Back"
  end

  test "destroying a Annot cell set" do
    visit annot_cell_sets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Annot cell set was successfully destroyed"
  end
end
