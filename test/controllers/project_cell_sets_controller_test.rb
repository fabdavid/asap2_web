require 'test_helper'

class ProjectCellSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_cell_set = project_cell_sets(:one)
  end

  test "should get index" do
    get project_cell_sets_url
    assert_response :success
  end

  test "should get new" do
    get new_project_cell_set_url
    assert_response :success
  end

  test "should create project_cell_set" do
    assert_difference('ProjectCellSet.count') do
      post project_cell_sets_url, params: { project_cell_set: {  } }
    end

    assert_redirected_to project_cell_set_url(ProjectCellSet.last)
  end

  test "should show project_cell_set" do
    get project_cell_set_url(@project_cell_set)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_cell_set_url(@project_cell_set)
    assert_response :success
  end

  test "should update project_cell_set" do
    patch project_cell_set_url(@project_cell_set), params: { project_cell_set: {  } }
    assert_redirected_to project_cell_set_url(@project_cell_set)
  end

  test "should destroy project_cell_set" do
    assert_difference('ProjectCellSet.count', -1) do
      delete project_cell_set_url(@project_cell_set)
    end

    assert_redirected_to project_cell_sets_url
  end
end
