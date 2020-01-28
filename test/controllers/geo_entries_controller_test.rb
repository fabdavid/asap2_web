require 'test_helper'

class GeoEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @geo_entry = geo_entries(:one)
  end

  test "should get index" do
    get geo_entries_url
    assert_response :success
  end

  test "should get new" do
    get new_geo_entry_url
    assert_response :success
  end

  test "should create geo_entry" do
    assert_difference('GeoEntry.count') do
      post geo_entries_url, params: { geo_entry: {  } }
    end

    assert_redirected_to geo_entry_url(GeoEntry.last)
  end

  test "should show geo_entry" do
    get geo_entry_url(@geo_entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_geo_entry_url(@geo_entry)
    assert_response :success
  end

  test "should update geo_entry" do
    patch geo_entry_url(@geo_entry), params: { geo_entry: {  } }
    assert_redirected_to geo_entry_url(@geo_entry)
  end

  test "should destroy geo_entry" do
    assert_difference('GeoEntry.count', -1) do
      delete geo_entry_url(@geo_entry)
    end

    assert_redirected_to geo_entries_url
  end
end
