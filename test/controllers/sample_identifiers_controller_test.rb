require 'test_helper'

class SampleIdentifiersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sample_identifier = sample_identifiers(:one)
  end

  test "should get index" do
    get sample_identifiers_url
    assert_response :success
  end

  test "should get new" do
    get new_sample_identifier_url
    assert_response :success
  end

  test "should create sample_identifier" do
    assert_difference('SampleIdentifier.count') do
      post sample_identifiers_url, params: { sample_identifier: {  } }
    end

    assert_redirected_to sample_identifier_url(SampleIdentifier.last)
  end

  test "should show sample_identifier" do
    get sample_identifier_url(@sample_identifier)
    assert_response :success
  end

  test "should get edit" do
    get edit_sample_identifier_url(@sample_identifier)
    assert_response :success
  end

  test "should update sample_identifier" do
    patch sample_identifier_url(@sample_identifier), params: { sample_identifier: {  } }
    assert_redirected_to sample_identifier_url(@sample_identifier)
  end

  test "should destroy sample_identifier" do
    assert_difference('SampleIdentifier.count', -1) do
      delete sample_identifier_url(@sample_identifier)
    end

    assert_redirected_to sample_identifiers_url
  end
end
