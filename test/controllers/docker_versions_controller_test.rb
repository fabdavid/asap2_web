require 'test_helper'

class DockerVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @docker_version = docker_versions(:one)
  end

  test "should get index" do
    get docker_versions_url
    assert_response :success
  end

  test "should get new" do
    get new_docker_version_url
    assert_response :success
  end

  test "should create docker_version" do
    assert_difference('DockerVersion.count') do
      post docker_versions_url, params: { docker_version: {  } }
    end

    assert_redirected_to docker_version_url(DockerVersion.last)
  end

  test "should show docker_version" do
    get docker_version_url(@docker_version)
    assert_response :success
  end

  test "should get edit" do
    get edit_docker_version_url(@docker_version)
    assert_response :success
  end

  test "should update docker_version" do
    patch docker_version_url(@docker_version), params: { docker_version: {  } }
    assert_redirected_to docker_version_url(@docker_version)
  end

  test "should destroy docker_version" do
    assert_difference('DockerVersion.count', -1) do
      delete docker_version_url(@docker_version)
    end

    assert_redirected_to docker_versions_url
  end
end
