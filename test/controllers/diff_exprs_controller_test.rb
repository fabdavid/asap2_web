require 'test_helper'

class DiffExprsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @diff_expr = diff_exprs(:one)
  end

  test "should get index" do
    get diff_exprs_url
    assert_response :success
  end

  test "should get new" do
    get new_diff_expr_url
    assert_response :success
  end

  test "should create diff_expr" do
    assert_difference('DiffExpr.count') do
      post diff_exprs_url, params: { diff_expr: {  } }
    end

    assert_redirected_to diff_expr_url(DiffExpr.last)
  end

  test "should show diff_expr" do
    get diff_expr_url(@diff_expr)
    assert_response :success
  end

  test "should get edit" do
    get edit_diff_expr_url(@diff_expr)
    assert_response :success
  end

  test "should update diff_expr" do
    patch diff_expr_url(@diff_expr), params: { diff_expr: {  } }
    assert_redirected_to diff_expr_url(@diff_expr)
  end

  test "should destroy diff_expr" do
    assert_difference('DiffExpr.count', -1) do
      delete diff_expr_url(@diff_expr)
    end

    assert_redirected_to diff_exprs_url
  end
end
