require 'test_helper'

class CorrelationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @correlation = correlations(:one)
  end

  test "should get index" do
    get correlations_url
    assert_response :success
  end

  test "should get new" do
    get new_correlation_url
    assert_response :success
  end

  test "should create correlation" do
    assert_difference('Correlation.count') do
      post correlations_url, params: { correlation: {  } }
    end

    assert_redirected_to correlation_url(Correlation.last)
  end

  test "should show correlation" do
    get correlation_url(@correlation)
    assert_response :success
  end

  test "should get edit" do
    get edit_correlation_url(@correlation)
    assert_response :success
  end

  test "should update correlation" do
    patch correlation_url(@correlation), params: { correlation: {  } }
    assert_redirected_to correlation_url(@correlation)
  end

  test "should destroy correlation" do
    assert_difference('Correlation.count', -1) do
      delete correlation_url(@correlation)
    end

    assert_redirected_to correlations_url
  end
end
