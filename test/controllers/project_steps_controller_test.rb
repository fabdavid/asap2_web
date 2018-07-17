require 'test_helper'

class ProjectStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_step = project_steps(:one)
  end

  test "should get index" do
    get project_steps_url
    assert_response :success
  end

  test "should get new" do
    get new_project_step_url
    assert_response :success
  end

  test "should create project_step" do
    assert_difference('ProjectStep.count') do
      post project_steps_url, params: { project_step: {  } }
    end

    assert_redirected_to project_step_url(ProjectStep.last)
  end

  test "should show project_step" do
    get project_step_url(@project_step)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_step_url(@project_step)
    assert_response :success
  end

  test "should update project_step" do
    patch project_step_url(@project_step), params: { project_step: {  } }
    assert_redirected_to project_step_url(@project_step)
  end

  test "should destroy project_step" do
    assert_difference('ProjectStep.count', -1) do
      delete project_step_url(@project_step)
    end

    assert_redirected_to project_steps_url
  end
end
