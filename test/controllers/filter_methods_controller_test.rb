require 'test_helper'

class FilterMethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filter_method = filter_methods(:one)
  end

  test "should get index" do
    get filter_methods_url
    assert_response :success
  end

  test "should get new" do
    get new_filter_method_url
    assert_response :success
  end

  test "should create filter_method" do
    assert_difference('FilterMethod.count') do
      post filter_methods_url, params: { filter_method: {  } }
    end

    assert_redirected_to filter_method_url(FilterMethod.last)
  end

  test "should show filter_method" do
    get filter_method_url(@filter_method)
    assert_response :success
  end

  test "should get edit" do
    get edit_filter_method_url(@filter_method)
    assert_response :success
  end

  test "should update filter_method" do
    patch filter_method_url(@filter_method), params: { filter_method: {  } }
    assert_redirected_to filter_method_url(@filter_method)
  end

  test "should destroy filter_method" do
    assert_difference('FilterMethod.count', -1) do
      delete filter_method_url(@filter_method)
    end

    assert_redirected_to filter_methods_url
  end
end
