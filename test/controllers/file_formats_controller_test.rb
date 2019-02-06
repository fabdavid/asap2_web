require 'test_helper'

class FileFormatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @file_format = file_formats(:one)
  end

  test "should get index" do
    get file_formats_url
    assert_response :success
  end

  test "should get new" do
    get new_file_format_url
    assert_response :success
  end

  test "should create file_format" do
    assert_difference('FileFormat.count') do
      post file_formats_url, params: { file_format: {  } }
    end

    assert_redirected_to file_format_url(FileFormat.last)
  end

  test "should show file_format" do
    get file_format_url(@file_format)
    assert_response :success
  end

  test "should get edit" do
    get edit_file_format_url(@file_format)
    assert_response :success
  end

  test "should update file_format" do
    patch file_format_url(@file_format), params: { file_format: {  } }
    assert_redirected_to file_format_url(@file_format)
  end

  test "should destroy file_format" do
    assert_difference('FileFormat.count', -1) do
      delete file_format_url(@file_format)
    end

    assert_redirected_to file_formats_url
  end
end
