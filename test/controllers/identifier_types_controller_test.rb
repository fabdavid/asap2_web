require 'test_helper'

class IdentifierTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @identifier_type = identifier_types(:one)
  end

  test "should get index" do
    get identifier_types_url
    assert_response :success
  end

  test "should get new" do
    get new_identifier_type_url
    assert_response :success
  end

  test "should create identifier_type" do
    assert_difference('IdentifierType.count') do
      post identifier_types_url, params: { identifier_type: {  } }
    end

    assert_redirected_to identifier_type_url(IdentifierType.last)
  end

  test "should show identifier_type" do
    get identifier_type_url(@identifier_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_identifier_type_url(@identifier_type)
    assert_response :success
  end

  test "should update identifier_type" do
    patch identifier_type_url(@identifier_type), params: { identifier_type: {  } }
    assert_redirected_to identifier_type_url(@identifier_type)
  end

  test "should destroy identifier_type" do
    assert_difference('IdentifierType.count', -1) do
      delete identifier_type_url(@identifier_type)
    end

    assert_redirected_to identifier_types_url
  end
end
