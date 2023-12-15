require "application_system_test_case"

class ProjectCellSetsTest < ApplicationSystemTestCase
  setup do
    @project_cell_set = project_cell_sets(:one)
  end

  test "visiting the index" do
    visit project_cell_sets_url
    assert_selector "h1", text: "Project Cell Sets"
  end

  test "creating a Project cell set" do
    visit project_cell_sets_url
    click_on "New Project Cell Set"

    click_on "Create Project cell set"

    assert_text "Project cell set was successfully created"
    click_on "Back"
  end

  test "updating a Project cell set" do
    visit project_cell_sets_url
    click_on "Edit", match: :first

    click_on "Update Project cell set"

    assert_text "Project cell set was successfully updated"
    click_on "Back"
  end

  test "destroying a Project cell set" do
    visit project_cell_sets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Project cell set was successfully destroyed"
  end
end
