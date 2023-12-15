require 'test_helper'

class ClaSourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cla_source = cla_sources(:one)
  end

  test "should get index" do
    get cla_sources_url
    assert_response :success
  end

  test "should get new" do
    get new_cla_source_url
    assert_response :success
  end

  test "should create cla_source" do
    assert_difference('ClaSource.count') do
      post cla_sources_url, params: { cla_source: {  } }
    end

    assert_redirected_to cla_source_url(ClaSource.last)
  end

  test "should show cla_source" do
    get cla_source_url(@cla_source)
    assert_response :success
  end

  test "should get edit" do
    get edit_cla_source_url(@cla_source)
    assert_response :success
  end

  test "should update cla_source" do
    patch cla_source_url(@cla_source), params: { cla_source: {  } }
    assert_redirected_to cla_source_url(@cla_source)
  end

  test "should destroy cla_source" do
    assert_difference('ClaSource.count', -1) do
      delete cla_source_url(@cla_source)
    end

    assert_redirected_to cla_sources_url
  end
end
