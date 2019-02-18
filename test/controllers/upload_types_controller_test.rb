require 'test_helper'

class UploadTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @upload_type = upload_types(:one)
  end

  test "should get index" do
    get upload_types_url
    assert_response :success
  end

  test "should get new" do
    get new_upload_type_url
    assert_response :success
  end

  test "should create upload_type" do
    assert_difference('UploadType.count') do
      post upload_types_url, params: { upload_type: {  } }
    end

    assert_redirected_to upload_type_url(UploadType.last)
  end

  test "should show upload_type" do
    get upload_type_url(@upload_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_upload_type_url(@upload_type)
    assert_response :success
  end

  test "should update upload_type" do
    patch upload_type_url(@upload_type), params: { upload_type: {  } }
    assert_redirected_to upload_type_url(@upload_type)
  end

  test "should destroy upload_type" do
    assert_difference('UploadType.count', -1) do
      delete upload_type_url(@upload_type)
    end

    assert_redirected_to upload_types_url
  end
end
