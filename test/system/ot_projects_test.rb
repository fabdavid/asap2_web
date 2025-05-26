require "application_system_test_case"

class OtProjectsTest < ApplicationSystemTestCase
  setup do
    @ot_project = ot_projects(:one)
  end

  test "visiting the index" do
    visit ot_projects_url
    assert_selector "h1", text: "Ot Projects"
  end

  test "creating a Ot project" do
    visit ot_projects_url
    click_on "New Ot Project"

    click_on "Create Ot project"

    assert_text "Ot project was successfully created"
    click_on "Back"
  end

  test "updating a Ot project" do
    visit ot_projects_url
    click_on "Edit", match: :first

    click_on "Update Ot project"

    assert_text "Ot project was successfully updated"
    click_on "Back"
  end

  test "destroying a Ot project" do
    visit ot_projects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ot project was successfully destroyed"
  end
end
