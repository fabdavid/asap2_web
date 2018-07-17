require 'test_helper'

class ProjectDimReductionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_dim_reduction = project_dim_reductions(:one)
  end

  test "should get index" do
    get project_dim_reductions_url
    assert_response :success
  end

  test "should get new" do
    get new_project_dim_reduction_url
    assert_response :success
  end

  test "should create project_dim_reduction" do
    assert_difference('ProjectDimReduction.count') do
      post project_dim_reductions_url, params: { project_dim_reduction: {  } }
    end

    assert_redirected_to project_dim_reduction_url(ProjectDimReduction.last)
  end

  test "should show project_dim_reduction" do
    get project_dim_reduction_url(@project_dim_reduction)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_dim_reduction_url(@project_dim_reduction)
    assert_response :success
  end

  test "should update project_dim_reduction" do
    patch project_dim_reduction_url(@project_dim_reduction), params: { project_dim_reduction: {  } }
    assert_redirected_to project_dim_reduction_url(@project_dim_reduction)
  end

  test "should destroy project_dim_reduction" do
    assert_difference('ProjectDimReduction.count', -1) do
      delete project_dim_reduction_url(@project_dim_reduction)
    end

    assert_redirected_to project_dim_reductions_url
  end
end
