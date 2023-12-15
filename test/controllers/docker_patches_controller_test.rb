require 'test_helper'

class DockerPatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @docker_patch = docker_patches(:one)
  end

  test "should get index" do
    get docker_patches_url
    assert_response :success
  end

  test "should get new" do
    get new_docker_patch_url
    assert_response :success
  end

  test "should create docker_patch" do
    assert_difference('DockerPatch.count') do
      post docker_patches_url, params: { docker_patch: {  } }
    end

    assert_redirected_to docker_patch_url(DockerPatch.last)
  end

  test "should show docker_patch" do
    get docker_patch_url(@docker_patch)
    assert_response :success
  end

  test "should get edit" do
    get edit_docker_patch_url(@docker_patch)
    assert_response :success
  end

  test "should update docker_patch" do
    patch docker_patch_url(@docker_patch), params: { docker_patch: {  } }
    assert_redirected_to docker_patch_url(@docker_patch)
  end

  test "should destroy docker_patch" do
    assert_difference('DockerPatch.count', -1) do
      delete docker_patch_url(@docker_patch)
    end

    assert_redirected_to docker_patches_url
  end
end
