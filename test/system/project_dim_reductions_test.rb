require "application_system_test_case"

class ProjectDimReductionsTest < ApplicationSystemTestCase
  setup do
    @project_dim_reduction = project_dim_reductions(:one)
  end

  test "visiting the index" do
    visit project_dim_reductions_url
    assert_selector "h1", text: "Project Dim Reductions"
  end

  test "creating a Project dim reduction" do
    visit project_dim_reductions_url
    click_on "New Project Dim Reduction"

    click_on "Create Project dim reduction"

    assert_text "Project dim reduction was successfully created"
    click_on "Back"
  end

  test "updating a Project dim reduction" do
    visit project_dim_reductions_url
    click_on "Edit", match: :first

    click_on "Update Project dim reduction"

    assert_text "Project dim reduction was successfully updated"
    click_on "Back"
  end

  test "destroying a Project dim reduction" do
    visit project_dim_reductions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Project dim reduction was successfully destroyed"
  end
end
