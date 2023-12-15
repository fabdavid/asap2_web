require 'test_helper'

class TmpFosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tmp_fo = tmp_fos(:one)
  end

  test "should get index" do
    get tmp_fos_url
    assert_response :success
  end

  test "should get new" do
    get new_tmp_fo_url
    assert_response :success
  end

  test "should create tmp_fo" do
    assert_difference('TmpFo.count') do
      post tmp_fos_url, params: { tmp_fo: {  } }
    end

    assert_redirected_to tmp_fo_url(TmpFo.last)
  end

  test "should show tmp_fo" do
    get tmp_fo_url(@tmp_fo)
    assert_response :success
  end

  test "should get edit" do
    get edit_tmp_fo_url(@tmp_fo)
    assert_response :success
  end

  test "should update tmp_fo" do
    patch tmp_fo_url(@tmp_fo), params: { tmp_fo: {  } }
    assert_redirected_to tmp_fo_url(@tmp_fo)
  end

  test "should destroy tmp_fo" do
    assert_difference('TmpFo.count', -1) do
      delete tmp_fo_url(@tmp_fo)
    end

    assert_redirected_to tmp_fos_url
  end
end
