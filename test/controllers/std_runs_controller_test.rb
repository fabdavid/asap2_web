require 'test_helper'

class StdRunsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @std_run = std_runs(:one)
  end

  test "should get index" do
    get std_runs_url
    assert_response :success
  end

  test "should get new" do
    get new_std_run_url
    assert_response :success
  end

  test "should create std_run" do
    assert_difference('StdRun.count') do
      post std_runs_url, params: { std_run: {  } }
    end

    assert_redirected_to std_run_url(StdRun.last)
  end

  test "should show std_run" do
    get std_run_url(@std_run)
    assert_response :success
  end

  test "should get edit" do
    get edit_std_run_url(@std_run)
    assert_response :success
  end

  test "should update std_run" do
    patch std_run_url(@std_run), params: { std_run: {  } }
    assert_redirected_to std_run_url(@std_run)
  end

  test "should destroy std_run" do
    assert_difference('StdRun.count', -1) do
      delete std_run_url(@std_run)
    end

    assert_redirected_to std_runs_url
  end
end
