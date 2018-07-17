require 'test_helper'

class NormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @norm = norms(:one)
  end

  test "should get index" do
    get norms_url
    assert_response :success
  end

  test "should get new" do
    get new_norm_url
    assert_response :success
  end

  test "should create norm" do
    assert_difference('Norm.count') do
      post norms_url, params: { norm: {  } }
    end

    assert_redirected_to norm_url(Norm.last)
  end

  test "should show norm" do
    get norm_url(@norm)
    assert_response :success
  end

  test "should get edit" do
    get edit_norm_url(@norm)
    assert_response :success
  end

  test "should update norm" do
    patch norm_url(@norm), params: { norm: {  } }
    assert_redirected_to norm_url(@norm)
  end

  test "should destroy norm" do
    assert_difference('Norm.count', -1) do
      delete norm_url(@norm)
    end

    assert_redirected_to norms_url
  end
end
