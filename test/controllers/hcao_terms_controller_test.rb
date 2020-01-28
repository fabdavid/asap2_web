require 'test_helper'

class HcaoTermsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hcao_term = hcao_terms(:one)
  end

  test "should get index" do
    get hcao_terms_url
    assert_response :success
  end

  test "should get new" do
    get new_hcao_term_url
    assert_response :success
  end

  test "should create hcao_term" do
    assert_difference('HcaoTerm.count') do
      post hcao_terms_url, params: { hcao_term: {  } }
    end

    assert_redirected_to hcao_term_url(HcaoTerm.last)
  end

  test "should show hcao_term" do
    get hcao_term_url(@hcao_term)
    assert_response :success
  end

  test "should get edit" do
    get edit_hcao_term_url(@hcao_term)
    assert_response :success
  end

  test "should update hcao_term" do
    patch hcao_term_url(@hcao_term), params: { hcao_term: {  } }
    assert_redirected_to hcao_term_url(@hcao_term)
  end

  test "should destroy hcao_term" do
    assert_difference('HcaoTerm.count', -1) do
      delete hcao_term_url(@hcao_term)
    end

    assert_redirected_to hcao_terms_url
  end
end
