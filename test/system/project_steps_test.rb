require "application_system_test_case"

class ProjectStepsTest < ApplicationSystemTestCase
  setup do
    @project_step = project_steps(:one)
  end

  test "visiting the index" do
    visit project_steps_url
    assert_selector "h1", text: "Project Steps"
  end

  test "creating a Project step" do
    visit project_steps_url
    click_on "New Project Step"

    click_on "Create Project step"

    assert_text "Project step was successfully created"
    click_on "Back"
  end

  test "updating a Project step" do
    visit project_steps_url
    click_on "Edit", match: :first

    click_on "Update Project step"

    assert_text "Project step was successfully updated"
    click_on "Back"
  end

  test "destroying a Project step" do
    visit project_steps_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Project step was successfully destroyed"
  end
end
