require 'test_helper'

class DelRunsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @del_run = del_runs(:one)
  end

  test "should get index" do
    get del_runs_url
    assert_response :success
  end

  test "should get new" do
    get new_del_run_url
    assert_response :success
  end

  test "should create del_run" do
    assert_difference('DelRun.count') do
      post del_runs_url, params: { del_run: {  } }
    end

    assert_redirected_to del_run_url(DelRun.last)
  end

  test "should show del_run" do
    get del_run_url(@del_run)
    assert_response :success
  end

  test "should get edit" do
    get edit_del_run_url(@del_run)
    assert_response :success
  end

  test "should update del_run" do
    patch del_run_url(@del_run), params: { del_run: {  } }
    assert_redirected_to del_run_url(@del_run)
  end

  test "should destroy del_run" do
    assert_difference('DelRun.count', -1) do
      delete del_run_url(@del_run)
    end

    assert_redirected_to del_runs_url
  end
end
