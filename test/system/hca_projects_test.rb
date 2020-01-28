require "application_system_test_case"

class HcaProjectsTest < ApplicationSystemTestCase
  setup do
    @hca_project = hca_projects(:one)
  end

  test "visiting the index" do
    visit hca_projects_url
    assert_selector "h1", text: "Hca Projects"
  end

  test "creating a Hca project" do
    visit hca_projects_url
    click_on "New Hca Project"

    click_on "Create Hca project"

    assert_text "Hca project was successfully created"
    click_on "Back"
  end

  test "updating a Hca project" do
    visit hca_projects_url
    click_on "Edit", match: :first

    click_on "Update Hca project"

    assert_text "Hca project was successfully updated"
    click_on "Back"
  end

  test "destroying a Hca project" do
    visit hca_projects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Hca project was successfully destroyed"
  end
end
