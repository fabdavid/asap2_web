require 'test_helper'

class SharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @share = shares(:one)
  end

  test "should get index" do
    get shares_url
    assert_response :success
  end

  test "should get new" do
    get new_share_url
    assert_response :success
  end

  test "should create share" do
    assert_difference('Share.count') do
      post shares_url, params: { share: {  } }
    end

    assert_redirected_to share_url(Share.last)
  end

  test "should show share" do
    get share_url(@share)
    assert_response :success
  end

  test "should get edit" do
    get edit_share_url(@share)
    assert_response :success
  end

  test "should update share" do
    patch share_url(@share), params: { share: {  } }
    assert_redirected_to share_url(@share)
  end

  test "should destroy share" do
    assert_difference('Share.count', -1) do
      delete share_url(@share)
    end

    assert_redirected_to shares_url
  end
end
