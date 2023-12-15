require "application_system_test_case"

class DockerPatchesTest < ApplicationSystemTestCase
  setup do
    @docker_patch = docker_patches(:one)
  end

  test "visiting the index" do
    visit docker_patches_url
    assert_selector "h1", text: "Docker Patches"
  end

  test "creating a Docker patch" do
    visit docker_patches_url
    click_on "New Docker Patch"

    click_on "Create Docker patch"

    assert_text "Docker patch was successfully created"
    click_on "Back"
  end

  test "updating a Docker patch" do
    visit docker_patches_url
    click_on "Edit", match: :first

    click_on "Update Docker patch"

    assert_text "Docker patch was successfully updated"
    click_on "Back"
  end

  test "destroying a Docker patch" do
    visit docker_patches_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Docker patch was successfully destroyed"
  end
end
