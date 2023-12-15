require 'test_helper'

class OrcidUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @orcid_user = orcid_users(:one)
  end

  test "should get index" do
    get orcid_users_url
    assert_response :success
  end

  test "should get new" do
    get new_orcid_user_url
    assert_response :success
  end

  test "should create orcid_user" do
    assert_difference('OrcidUser.count') do
      post orcid_users_url, params: { orcid_user: {  } }
    end

    assert_redirected_to orcid_user_url(OrcidUser.last)
  end

  test "should show orcid_user" do
    get orcid_user_url(@orcid_user)
    assert_response :success
  end

  test "should get edit" do
    get edit_orcid_user_url(@orcid_user)
    assert_response :success
  end

  test "should update orcid_user" do
    patch orcid_user_url(@orcid_user), params: { orcid_user: {  } }
    assert_redirected_to orcid_user_url(@orcid_user)
  end

  test "should destroy orcid_user" do
    assert_difference('OrcidUser.count', -1) do
      delete orcid_user_url(@orcid_user)
    end

    assert_redirected_to orcid_users_url
  end
end
