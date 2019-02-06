require 'test_helper'

class ReqsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @req = reqs(:one)
  end

  test "should get index" do
    get reqs_url
    assert_response :success
  end

  test "should get new" do
    get new_req_url
    assert_response :success
  end

  test "should create req" do
    assert_difference('Req.count') do
      post reqs_url, params: { req: {  } }
    end

    assert_redirected_to req_url(Req.last)
  end

  test "should show req" do
    get req_url(@req)
    assert_response :success
  end

  test "should get edit" do
    get edit_req_url(@req)
    assert_response :success
  end

  test "should update req" do
    patch req_url(@req), params: { req: {  } }
    assert_redirected_to req_url(@req)
  end

  test "should destroy req" do
    assert_difference('Req.count', -1) do
      delete req_url(@req)
    end

    assert_redirected_to reqs_url
  end
end
