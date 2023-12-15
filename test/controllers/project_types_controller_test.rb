require 'test_helper'

class ProjectTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_type = project_types(:one)
  end

  test "should get index" do
    get project_types_url
    assert_response :success
  end

  test "should get new" do
    get new_project_type_url
    assert_response :success
  end

  test "should create project_type" do
    assert_difference('ProjectType.count') do
      post project_types_url, params: { project_type: {  } }
    end

    assert_redirected_to project_type_url(ProjectType.last)
  end

  test "should show project_type" do
    get project_type_url(@project_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_type_url(@project_type)
    assert_response :success
  end

  test "should update project_type" do
    patch project_type_url(@project_type), params: { project_type: {  } }
    assert_redirected_to project_type_url(@project_type)
  end

  test "should destroy project_type" do
    assert_difference('ProjectType.count', -1) do
      delete project_type_url(@project_type)
    end

    assert_redirected_to project_types_url
  end
end
