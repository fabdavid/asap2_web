require 'test_helper'

class OutputAttrsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @output_attr = output_attrs(:one)
  end

  test "should get index" do
    get output_attrs_url
    assert_response :success
  end

  test "should get new" do
    get new_output_attr_url
    assert_response :success
  end

  test "should create output_attr" do
    assert_difference('OutputAttr.count') do
      post output_attrs_url, params: { output_attr: {  } }
    end

    assert_redirected_to output_attr_url(OutputAttr.last)
  end

  test "should show output_attr" do
    get output_attr_url(@output_attr)
    assert_response :success
  end

  test "should get edit" do
    get edit_output_attr_url(@output_attr)
    assert_response :success
  end

  test "should update output_attr" do
    patch output_attr_url(@output_attr), params: { output_attr: {  } }
    assert_redirected_to output_attr_url(@output_attr)
  end

  test "should destroy output_attr" do
    assert_difference('OutputAttr.count', -1) do
      delete output_attr_url(@output_attr)
    end

    assert_redirected_to output_attrs_url
  end
end
