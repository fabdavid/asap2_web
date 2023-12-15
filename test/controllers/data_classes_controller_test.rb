require 'test_helper'

class DataClassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @data_class = data_classes(:one)
  end

  test "should get index" do
    get data_classes_url
    assert_response :success
  end

  test "should get new" do
    get new_data_class_url
    assert_response :success
  end

  test "should create data_class" do
    assert_difference('DataClass.count') do
      post data_classes_url, params: { data_class: {  } }
    end

    assert_redirected_to data_class_url(DataClass.last)
  end

  test "should show data_class" do
    get data_class_url(@data_class)
    assert_response :success
  end

  test "should get edit" do
    get edit_data_class_url(@data_class)
    assert_response :success
  end

  test "should update data_class" do
    patch data_class_url(@data_class), params: { data_class: {  } }
    assert_redirected_to data_class_url(@data_class)
  end

  test "should destroy data_class" do
    assert_difference('DataClass.count', -1) do
      delete data_class_url(@data_class)
    end

    assert_redirected_to data_classes_url
  end
end
