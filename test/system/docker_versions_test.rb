require "application_system_test_case"

class DockerVersionsTest < ApplicationSystemTestCase
  setup do
    @docker_version = docker_versions(:one)
  end

  test "visiting the index" do
    visit docker_versions_url
    assert_selector "h1", text: "Docker Versions"
  end

  test "creating a Docker version" do
    visit docker_versions_url
    click_on "New Docker Version"

    click_on "Create Docker version"

    assert_text "Docker version was successfully created"
    click_on "Back"
  end

  test "updating a Docker version" do
    visit docker_versions_url
    click_on "Edit", match: :first

    click_on "Update Docker version"

    assert_text "Docker version was successfully updated"
    click_on "Back"
  end

  test "destroying a Docker version" do
    visit docker_versions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Docker version was successfully destroyed"
  end
end
