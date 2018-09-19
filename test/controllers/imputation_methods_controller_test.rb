require 'test_helper'

class ImputationMethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @imputation_method = imputation_methods(:one)
  end

  test "should get index" do
    get imputation_methods_url
    assert_response :success
  end

  test "should get new" do
    get new_imputation_method_url
    assert_response :success
  end

  test "should create imputation_method" do
    assert_difference('ImputationMethod.count') do
      post imputation_methods_url, params: { imputation_method: {  } }
    end

    assert_redirected_to imputation_method_url(ImputationMethod.last)
  end

  test "should show imputation_method" do
    get imputation_method_url(@imputation_method)
    assert_response :success
  end

  test "should get edit" do
    get edit_imputation_method_url(@imputation_method)
    assert_response :success
  end

  test "should update imputation_method" do
    patch imputation_method_url(@imputation_method), params: { imputation_method: {  } }
    assert_redirected_to imputation_method_url(@imputation_method)
  end

  test "should destroy imputation_method" do
    assert_difference('ImputationMethod.count', -1) do
      delete imputation_method_url(@imputation_method)
    end

    assert_redirected_to imputation_methods_url
  end
end
