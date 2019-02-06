require 'test_helper'

class TrajectoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trajectory = trajectories(:one)
  end

  test "should get index" do
    get trajectories_url
    assert_response :success
  end

  test "should get new" do
    get new_trajectory_url
    assert_response :success
  end

  test "should create trajectory" do
    assert_difference('Trajectory.count') do
      post trajectories_url, params: { trajectory: {  } }
    end

    assert_redirected_to trajectory_url(Trajectory.last)
  end

  test "should show trajectory" do
    get trajectory_url(@trajectory)
    assert_response :success
  end

  test "should get edit" do
    get edit_trajectory_url(@trajectory)
    assert_response :success
  end

  test "should update trajectory" do
    patch trajectory_url(@trajectory), params: { trajectory: {  } }
    assert_redirected_to trajectory_url(@trajectory)
  end

  test "should destroy trajectory" do
    assert_difference('Trajectory.count', -1) do
      delete trajectory_url(@trajectory)
    end

    assert_redirected_to trajectories_url
  end
end
