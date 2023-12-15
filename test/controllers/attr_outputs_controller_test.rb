require 'test_helper'

class AttrOutputsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attr_output = attr_outputs(:one)
  end

  test "should get index" do
    get attr_outputs_url
    assert_response :success
  end

  test "should get new" do
    get new_attr_output_url
    assert_response :success
  end

  test "should create attr_output" do
    assert_difference('AttrOutput.count') do
      post attr_outputs_url, params: { attr_output: {  } }
    end

    assert_redirected_to attr_output_url(AttrOutput.last)
  end

  test "should show attr_output" do
    get attr_output_url(@attr_output)
    assert_response :success
  end

  test "should get edit" do
    get edit_attr_output_url(@attr_output)
    assert_response :success
  end

  test "should update attr_output" do
    patch attr_output_url(@attr_output), params: { attr_output: {  } }
    assert_redirected_to attr_output_url(@attr_output)
  end

  test "should destroy attr_output" do
    assert_difference('AttrOutput.count', -1) do
      delete attr_output_url(@attr_output)
    end

    assert_redirected_to attr_outputs_url
  end
end
