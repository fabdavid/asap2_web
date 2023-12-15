require 'test_helper'

class ExpEntryIdentifiersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exp_entry_identifier = exp_entry_identifiers(:one)
  end

  test "should get index" do
    get exp_entry_identifiers_url
    assert_response :success
  end

  test "should get new" do
    get new_exp_entry_identifier_url
    assert_response :success
  end

  test "should create exp_entry_identifier" do
    assert_difference('ExpEntryIdentifier.count') do
      post exp_entry_identifiers_url, params: { exp_entry_identifier: {  } }
    end

    assert_redirected_to exp_entry_identifier_url(ExpEntryIdentifier.last)
  end

  test "should show exp_entry_identifier" do
    get exp_entry_identifier_url(@exp_entry_identifier)
    assert_response :success
  end

  test "should get edit" do
    get edit_exp_entry_identifier_url(@exp_entry_identifier)
    assert_response :success
  end

  test "should update exp_entry_identifier" do
    patch exp_entry_identifier_url(@exp_entry_identifier), params: { exp_entry_identifier: {  } }
    assert_redirected_to exp_entry_identifier_url(@exp_entry_identifier)
  end

  test "should destroy exp_entry_identifier" do
    assert_difference('ExpEntryIdentifier.count', -1) do
      delete exp_entry_identifier_url(@exp_entry_identifier)
    end

    assert_redirected_to exp_entry_identifiers_url
  end
end
