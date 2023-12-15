require "application_system_test_case"

class DockerImagesTest < ApplicationSystemTestCase
  setup do
    @docker_image = docker_images(:one)
  end

  test "visiting the index" do
    visit docker_images_url
    assert_selector "h1", text: "Docker Images"
  end

  test "creating a Docker image" do
    visit docker_images_url
    click_on "New Docker Image"

    click_on "Create Docker image"

    assert_text "Docker image was successfully created"
    click_on "Back"
  end

  test "updating a Docker image" do
    visit docker_images_url
    click_on "Edit", match: :first

    click_on "Update Docker image"

    assert_text "Docker image was successfully updated"
    click_on "Back"
  end

  test "destroying a Docker image" do
    visit docker_images_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Docker image was successfully destroyed"
  end
end
