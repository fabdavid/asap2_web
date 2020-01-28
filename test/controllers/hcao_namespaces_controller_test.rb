require 'test_helper'

class HcaoNamespacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hcao_namespace = hcao_namespaces(:one)
  end

  test "should get index" do
    get hcao_namespaces_url
    assert_response :success
  end

  test "should get new" do
    get new_hcao_namespace_url
    assert_response :success
  end

  test "should create hcao_namespace" do
    assert_difference('HcaoNamespace.count') do
      post hcao_namespaces_url, params: { hcao_namespace: {  } }
    end

    assert_redirected_to hcao_namespace_url(HcaoNamespace.last)
  end

  test "should show hcao_namespace" do
    get hcao_namespace_url(@hcao_namespace)
    assert_response :success
  end

  test "should get edit" do
    get edit_hcao_namespace_url(@hcao_namespace)
    assert_response :success
  end

  test "should update hcao_namespace" do
    patch hcao_namespace_url(@hcao_namespace), params: { hcao_namespace: {  } }
    assert_redirected_to hcao_namespace_url(@hcao_namespace)
  end

  test "should destroy hcao_namespace" do
    assert_difference('HcaoNamespace.count', -1) do
      delete hcao_namespace_url(@hcao_namespace)
    end

    assert_redirected_to hcao_namespaces_url
  end
end
