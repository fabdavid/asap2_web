require 'test_helper'

class HcaProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hca_project = hca_projects(:one)
  end

  test "should get index" do
    get hca_projects_url
    assert_response :success
  end

  test "should get new" do
    get new_hca_project_url
    assert_response :success
  end

  test "should create hca_project" do
    assert_difference('HcaProject.count') do
      post hca_projects_url, params: { hca_project: {  } }
    end

    assert_redirected_to hca_project_url(HcaProject.last)
  end

  test "should show hca_project" do
    get hca_project_url(@hca_project)
    assert_response :success
  end

  test "should get edit" do
    get edit_hca_project_url(@hca_project)
    assert_response :success
  end

  test "should update hca_project" do
    patch hca_project_url(@hca_project), params: { hca_project: {  } }
    assert_redirected_to hca_project_url(@hca_project)
  end

  test "should destroy hca_project" do
    assert_difference('HcaProject.count', -1) do
      delete hca_project_url(@hca_project)
    end

    assert_redirected_to hca_projects_url
  end
end
