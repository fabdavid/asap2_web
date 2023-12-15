require "application_system_test_case"

class ProjectTypesTest < ApplicationSystemTestCase
  setup do
    @project_type = project_types(:one)
  end

  test "visiting the index" do
    visit project_types_url
    assert_selector "h1", text: "Project Types"
  end

  test "creating a Project type" do
    visit project_types_url
    click_on "New Project Type"

    click_on "Create Project type"

    assert_text "Project type was successfully created"
    click_on "Back"
  end

  test "updating a Project type" do
    visit project_types_url
    click_on "Edit", match: :first

    click_on "Update Project type"

    assert_text "Project type was successfully updated"
    click_on "Back"
  end

  test "destroying a Project type" do
    visit project_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Project type was successfully destroyed"
  end
end
