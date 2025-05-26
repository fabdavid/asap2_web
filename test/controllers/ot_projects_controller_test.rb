require 'test_helper'

class OtProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ot_project = ot_projects(:one)
  end

  test "should get index" do
    get ot_projects_url
    assert_response :success
  end

  test "should get new" do
    get new_ot_project_url
    assert_response :success
  end

  test "should create ot_project" do
    assert_difference('OtProject.count') do
      post ot_projects_url, params: { ot_project: {  } }
    end

    assert_redirected_to ot_project_url(OtProject.last)
  end

  test "should show ot_project" do
    get ot_project_url(@ot_project)
    assert_response :success
  end

  test "should get edit" do
    get edit_ot_project_url(@ot_project)
    assert_response :success
  end

  test "should update ot_project" do
    patch ot_project_url(@ot_project), params: { ot_project: {  } }
    assert_redirected_to ot_project_url(@ot_project)
  end

  test "should destroy ot_project" do
    assert_difference('OtProject.count', -1) do
      delete ot_project_url(@ot_project)
    end

    assert_redirected_to ot_projects_url
  end
end
