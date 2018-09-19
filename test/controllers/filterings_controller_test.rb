require 'test_helper'

class FilteringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filtering = filterings(:one)
  end

  test "should get index" do
    get filterings_url
    assert_response :success
  end

  test "should get new" do
    get new_filtering_url
    assert_response :success
  end

  test "should create filtering" do
    assert_difference('Filtering.count') do
      post filterings_url, params: { filtering: {  } }
    end

    assert_redirected_to filtering_url(Filtering.last)
  end

  test "should show filtering" do
    get filtering_url(@filtering)
    assert_response :success
  end

  test "should get edit" do
    get edit_filtering_url(@filtering)
    assert_response :success
  end

  test "should update filtering" do
    patch filtering_url(@filtering), params: { filtering: {  } }
    assert_redirected_to filtering_url(@filtering)
  end

  test "should destroy filtering" do
    assert_difference('Filtering.count', -1) do
      delete filtering_url(@filtering)
    end

    assert_redirected_to filterings_url
  end
end
