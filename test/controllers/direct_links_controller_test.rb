require 'test_helper'

class DirectLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @direct_link = direct_links(:one)
  end

  test "should get index" do
    get direct_links_url
    assert_response :success
  end

  test "should get new" do
    get new_direct_link_url
    assert_response :success
  end

  test "should create direct_link" do
    assert_difference('DirectLink.count') do
      post direct_links_url, params: { direct_link: {  } }
    end

    assert_redirected_to direct_link_url(DirectLink.last)
  end

  test "should show direct_link" do
    get direct_link_url(@direct_link)
    assert_response :success
  end

  test "should get edit" do
    get edit_direct_link_url(@direct_link)
    assert_response :success
  end

  test "should update direct_link" do
    patch direct_link_url(@direct_link), params: { direct_link: {  } }
    assert_redirected_to direct_link_url(@direct_link)
  end

  test "should destroy direct_link" do
    assert_difference('DirectLink.count', -1) do
      delete direct_link_url(@direct_link)
    end

    assert_redirected_to direct_links_url
  end
end
