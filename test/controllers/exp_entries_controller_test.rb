require 'test_helper'

class ExpEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exp_entry = exp_entries(:one)
  end

  test "should get index" do
    get exp_entries_url
    assert_response :success
  end

  test "should get new" do
    get new_exp_entry_url
    assert_response :success
  end

  test "should create exp_entry" do
    assert_difference('ExpEntry.count') do
      post exp_entries_url, params: { exp_entry: {  } }
    end

    assert_redirected_to exp_entry_url(ExpEntry.last)
  end

  test "should show exp_entry" do
    get exp_entry_url(@exp_entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_exp_entry_url(@exp_entry)
    assert_response :success
  end

  test "should update exp_entry" do
    patch exp_entry_url(@exp_entry), params: { exp_entry: {  } }
    assert_redirected_to exp_entry_url(@exp_entry)
  end

  test "should destroy exp_entry" do
    assert_difference('ExpEntry.count', -1) do
      delete exp_entry_url(@exp_entry)
    end

    assert_redirected_to exp_entries_url
  end
end
