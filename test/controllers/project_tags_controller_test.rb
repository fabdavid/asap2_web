require 'test_helper'

class ProjectTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_tag = project_tags(:one)
  end

  test "should get index" do
    get project_tags_url
    assert_response :success
  end

  test "should get new" do
    get new_project_tag_url
    assert_response :success
  end

  test "should create project_tag" do
    assert_difference('ProjectTag.count') do
      post project_tags_url, params: { project_tag: {  } }
    end

    assert_redirected_to project_tag_url(ProjectTag.last)
  end

  test "should show project_tag" do
    get project_tag_url(@project_tag)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_tag_url(@project_tag)
    assert_response :success
  end

  test "should update project_tag" do
    patch project_tag_url(@project_tag), params: { project_tag: {  } }
    assert_redirected_to project_tag_url(@project_tag)
  end

  test "should destroy project_tag" do
    assert_difference('ProjectTag.count', -1) do
      delete project_tag_url(@project_tag)
    end

    assert_redirected_to project_tags_url
  end
end
