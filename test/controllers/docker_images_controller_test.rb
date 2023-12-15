require 'test_helper'

class DockerImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @docker_image = docker_images(:one)
  end

  test "should get index" do
    get docker_images_url
    assert_response :success
  end

  test "should get new" do
    get new_docker_image_url
    assert_response :success
  end

  test "should create docker_image" do
    assert_difference('DockerImage.count') do
      post docker_images_url, params: { docker_image: {  } }
    end

    assert_redirected_to docker_image_url(DockerImage.last)
  end

  test "should show docker_image" do
    get docker_image_url(@docker_image)
    assert_response :success
  end

  test "should get edit" do
    get edit_docker_image_url(@docker_image)
    assert_response :success
  end

  test "should update docker_image" do
    patch docker_image_url(@docker_image), params: { docker_image: {  } }
    assert_redirected_to docker_image_url(@docker_image)
  end

  test "should destroy docker_image" do
    assert_difference('DockerImage.count', -1) do
      delete docker_image_url(@docker_image)
    end

    assert_redirected_to docker_images_url
  end
end
