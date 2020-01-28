require 'test_helper'

class EnsemblSubdomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ensembl_subdomain = ensembl_subdomains(:one)
  end

  test "should get index" do
    get ensembl_subdomains_url
    assert_response :success
  end

  test "should get new" do
    get new_ensembl_subdomain_url
    assert_response :success
  end

  test "should create ensembl_subdomain" do
    assert_difference('EnsemblSubdomain.count') do
      post ensembl_subdomains_url, params: { ensembl_subdomain: {  } }
    end

    assert_redirected_to ensembl_subdomain_url(EnsemblSubdomain.last)
  end

  test "should show ensembl_subdomain" do
    get ensembl_subdomain_url(@ensembl_subdomain)
    assert_response :success
  end

  test "should get edit" do
    get edit_ensembl_subdomain_url(@ensembl_subdomain)
    assert_response :success
  end

  test "should update ensembl_subdomain" do
    patch ensembl_subdomain_url(@ensembl_subdomain), params: { ensembl_subdomain: {  } }
    assert_redirected_to ensembl_subdomain_url(@ensembl_subdomain)
  end

  test "should destroy ensembl_subdomain" do
    assert_difference('EnsemblSubdomain.count', -1) do
      delete ensembl_subdomain_url(@ensembl_subdomain)
    end

    assert_redirected_to ensembl_subdomains_url
  end
end
