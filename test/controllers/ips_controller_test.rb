require 'test_helper'

class IpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ip = ips(:one)
  end

  test "should get index" do
    get ips_url
    assert_response :success
  end

  test "should get new" do
    get new_ip_url
    assert_response :success
  end

  test "should create ip" do
    assert_difference('Ip.count') do
      post ips_url, params: { ip: {  } }
    end

    assert_redirected_to ip_url(Ip.last)
  end

  test "should show ip" do
    get ip_url(@ip)
    assert_response :success
  end

  test "should get edit" do
    get edit_ip_url(@ip)
    assert_response :success
  end

  test "should update ip" do
    patch ip_url(@ip), params: { ip: {  } }
    assert_redirected_to ip_url(@ip)
  end

  test "should destroy ip" do
    assert_difference('Ip.count', -1) do
      delete ip_url(@ip)
    end

    assert_redirected_to ips_url
  end
end
