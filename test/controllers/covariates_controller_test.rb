require 'test_helper'

class CovariatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @covariate = covariates(:one)
  end

  test "should get index" do
    get covariates_url
    assert_response :success
  end

  test "should get new" do
    get new_covariate_url
    assert_response :success
  end

  test "should create covariate" do
    assert_difference('Covariate.count') do
      post covariates_url, params: { covariate: {  } }
    end

    assert_redirected_to covariate_url(Covariate.last)
  end

  test "should show covariate" do
    get covariate_url(@covariate)
    assert_response :success
  end

  test "should get edit" do
    get edit_covariate_url(@covariate)
    assert_response :success
  end

  test "should update covariate" do
    patch covariate_url(@covariate), params: { covariate: {  } }
    assert_redirected_to covariate_url(@covariate)
  end

  test "should destroy covariate" do
    assert_difference('Covariate.count', -1) do
      delete covariate_url(@covariate)
    end

    assert_redirected_to covariates_url
  end
end
