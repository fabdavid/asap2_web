require "application_system_test_case"

class OttProjectsTest < ApplicationSystemTestCase
  setup do
    @ott_project = ott_projects(:one)
  end

  test "visiting the index" do
    visit ott_projects_url
    assert_selector "h1", text: "Ott Projects"
  end

  test "creating a Ott project" do
    visit ott_projects_url
    click_on "New Ott Project"

    click_on "Create Ott project"

    assert_text "Ott project was successfully created"
    click_on "Back"
  end

  test "updating a Ott project" do
    visit ott_projects_url
    click_on "Edit", match: :first

    click_on "Update Ott project"

    assert_text "Ott project was successfully updated"
    click_on "Back"
  end

  test "destroying a Ott project" do
    visit ott_projects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ott project was successfully destroyed"
  end
end
