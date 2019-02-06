require 'test_helper'

class StdMethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @std_method = std_methods(:one)
  end

  test "should get index" do
    get std_methods_url
    assert_response :success
  end

  test "should get new" do
    get new_std_method_url
    assert_response :success
  end

  test "should create std_method" do
    assert_difference('StdMethod.count') do
      post std_methods_url, params: { std_method: {  } }
    end

    assert_redirected_to std_method_url(StdMethod.last)
  end

  test "should show std_method" do
    get std_method_url(@std_method)
    assert_response :success
  end

  test "should get edit" do
    get edit_std_method_url(@std_method)
    assert_response :success
  end

  test "should update std_method" do
    patch std_method_url(@std_method), params: { std_method: {  } }
    assert_redirected_to std_method_url(@std_method)
  end

  test "should destroy std_method" do
    assert_difference('StdMethod.count', -1) do
      delete std_method_url(@std_method)
    end

    assert_redirected_to std_methods_url
  end
end
