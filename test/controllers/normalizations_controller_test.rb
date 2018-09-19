require 'test_helper'

class NormalizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @normalization = normalizations(:one)
  end

  test "should get index" do
    get normalizations_url
    assert_response :success
  end

  test "should get new" do
    get new_normalization_url
    assert_response :success
  end

  test "should create normalization" do
    assert_difference('Normalization.count') do
      post normalizations_url, params: { normalization: {  } }
    end

    assert_redirected_to normalization_url(Normalization.last)
  end

  test "should show normalization" do
    get normalization_url(@normalization)
    assert_response :success
  end

  test "should get edit" do
    get edit_normalization_url(@normalization)
    assert_response :success
  end

  test "should update normalization" do
    patch normalization_url(@normalization), params: { normalization: {  } }
    assert_redirected_to normalization_url(@normalization)
  end

  test "should destroy normalization" do
    assert_difference('Normalization.count', -1) do
      delete normalization_url(@normalization)
    end

    assert_redirected_to normalizations_url
  end
end
