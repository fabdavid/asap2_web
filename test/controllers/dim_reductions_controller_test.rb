require 'test_helper'

class DimReductionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dim_reduction = dim_reductions(:one)
  end

  test "should get index" do
    get dim_reductions_url
    assert_response :success
  end

  test "should get new" do
    get new_dim_reduction_url
    assert_response :success
  end

  test "should create dim_reduction" do
    assert_difference('DimReduction.count') do
      post dim_reductions_url, params: { dim_reduction: {  } }
    end

    assert_redirected_to dim_reduction_url(DimReduction.last)
  end

  test "should show dim_reduction" do
    get dim_reduction_url(@dim_reduction)
    assert_response :success
  end

  test "should get edit" do
    get edit_dim_reduction_url(@dim_reduction)
    assert_response :success
  end

  test "should update dim_reduction" do
    patch dim_reduction_url(@dim_reduction), params: { dim_reduction: {  } }
    assert_redirected_to dim_reduction_url(@dim_reduction)
  end

  test "should destroy dim_reduction" do
    assert_difference('DimReduction.count', -1) do
      delete dim_reduction_url(@dim_reduction)
    end

    assert_redirected_to dim_reductions_url
  end
end
