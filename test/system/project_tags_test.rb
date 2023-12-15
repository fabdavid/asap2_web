require "application_system_test_case"

class ProjectTagsTest < ApplicationSystemTestCase
  setup do
    @project_tag = project_tags(:one)
  end

  test "visiting the index" do
    visit project_tags_url
    assert_selector "h1", text: "Project Tags"
  end

  test "creating a Project tag" do
    visit project_tags_url
    click_on "New Project Tag"

    click_on "Create Project tag"

    assert_text "Project tag was successfully created"
    click_on "Back"
  end

  test "updating a Project tag" do
    visit project_tags_url
    click_on "Edit", match: :first

    click_on "Update Project tag"

    assert_text "Project tag was successfully updated"
    click_on "Back"
  end

  test "destroying a Project tag" do
    visit project_tags_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Project tag was successfully destroyed"
  end
end
