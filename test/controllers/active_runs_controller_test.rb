require 'test_helper'

class ActiveRunsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @active_run = active_runs(:one)
  end

  test "should get index" do
    get active_runs_url
    assert_response :success
  end

  test "should get new" do
    get new_active_run_url
    assert_response :success
  end

  test "should create active_run" do
    assert_difference('ActiveRun.count') do
      post active_runs_url, params: { active_run: {  } }
    end

    assert_redirected_to active_run_url(ActiveRun.last)
  end

  test "should show active_run" do
    get active_run_url(@active_run)
    assert_response :success
  end

  test "should get edit" do
    get edit_active_run_url(@active_run)
    assert_response :success
  end

  test "should update active_run" do
    patch active_run_url(@active_run), params: { active_run: {  } }
    assert_redirected_to active_run_url(@active_run)
  end

  test "should destroy active_run" do
    assert_difference('ActiveRun.count', -1) do
      delete active_run_url(@active_run)
    end

    assert_redirected_to active_runs_url
  end
end
