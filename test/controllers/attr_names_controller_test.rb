require 'test_helper'

class AttrNamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attr_name = attr_names(:one)
  end

  test "should get index" do
    get attr_names_url
    assert_response :success
  end

  test "should get new" do
    get new_attr_name_url
    assert_response :success
  end

  test "should create attr_name" do
    assert_difference('AttrName.count') do
      post attr_names_url, params: { attr_name: {  } }
    end

    assert_redirected_to attr_name_url(AttrName.last)
  end

  test "should show attr_name" do
    get attr_name_url(@attr_name)
    assert_response :success
  end

  test "should get edit" do
    get edit_attr_name_url(@attr_name)
    assert_response :success
  end

  test "should update attr_name" do
    patch attr_name_url(@attr_name), params: { attr_name: {  } }
    assert_redirected_to attr_name_url(@attr_name)
  end

  test "should destroy attr_name" do
    assert_difference('AttrName.count', -1) do
      delete attr_name_url(@attr_name)
    end

    assert_redirected_to attr_names_url
  end
end
