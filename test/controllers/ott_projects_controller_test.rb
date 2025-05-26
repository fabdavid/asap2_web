require 'test_helper'

class OttProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ott_project = ott_projects(:one)
  end

  test "should get index" do
    get ott_projects_url
    assert_response :success
  end

  test "should get new" do
    get new_ott_project_url
    assert_response :success
  end

  test "should create ott_project" do
    assert_difference('OttProject.count') do
      post ott_projects_url, params: { ott_project: {  } }
    end

    assert_redirected_to ott_project_url(OttProject.last)
  end

  test "should show ott_project" do
    get ott_project_url(@ott_project)
    assert_response :success
  end

  test "should get edit" do
    get edit_ott_project_url(@ott_project)
    assert_response :success
  end

  test "should update ott_project" do
    patch ott_project_url(@ott_project), params: { ott_project: {  } }
    assert_redirected_to ott_project_url(@ott_project)
  end

  test "should destroy ott_project" do
    assert_difference('OttProject.count', -1) do
      delete ott_project_url(@ott_project)
    end

    assert_redirected_to ott_projects_url
  end
end
