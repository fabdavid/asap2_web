require "application_system_test_case"

class ProviderProjectsTest < ApplicationSystemTestCase
  setup do
    @provider_project = provider_projects(:one)
  end

  test "visiting the index" do
    visit provider_projects_url
    assert_selector "h1", text: "Provider Projects"
  end

  test "creating a Provider project" do
    visit provider_projects_url
    click_on "New Provider Project"

    click_on "Create Provider project"

    assert_text "Provider project was successfully created"
    click_on "Back"
  end

  test "updating a Provider project" do
    visit provider_projects_url
    click_on "Edit", match: :first

    click_on "Update Provider project"

    assert_text "Provider project was successfully updated"
    click_on "Back"
  end

  test "destroying a Provider project" do
    visit provider_projects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Provider project was successfully destroyed"
  end
end
