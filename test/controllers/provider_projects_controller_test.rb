require 'test_helper'

class ProviderProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @provider_project = provider_projects(:one)
  end

  test "should get index" do
    get provider_projects_url
    assert_response :success
  end

  test "should get new" do
    get new_provider_project_url
    assert_response :success
  end

  test "should create provider_project" do
    assert_difference('ProviderProject.count') do
      post provider_projects_url, params: { provider_project: {  } }
    end

    assert_redirected_to provider_project_url(ProviderProject.last)
  end

  test "should show provider_project" do
    get provider_project_url(@provider_project)
    assert_response :success
  end

  test "should get edit" do
    get edit_provider_project_url(@provider_project)
    assert_response :success
  end

  test "should update provider_project" do
    patch provider_project_url(@provider_project), params: { provider_project: {  } }
    assert_redirected_to provider_project_url(@provider_project)
  end

  test "should destroy provider_project" do
    assert_difference('ProviderProject.count', -1) do
      delete provider_project_url(@provider_project)
    end

    assert_redirected_to provider_projects_url
  end
end
