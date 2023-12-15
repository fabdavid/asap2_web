require 'test_helper'

class ClasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cla = clas(:one)
  end

  test "should get index" do
    get clas_url
    assert_response :success
  end

  test "should get new" do
    get new_cla_url
    assert_response :success
  end

  test "should create cla" do
    assert_difference('Cla.count') do
      post clas_url, params: { cla: {  } }
    end

    assert_redirected_to cla_url(Cla.last)
  end

  test "should show cla" do
    get cla_url(@cla)
    assert_response :success
  end

  test "should get edit" do
    get edit_cla_url(@cla)
    assert_response :success
  end

  test "should update cla" do
    patch cla_url(@cla), params: { cla: {  } }
    assert_redirected_to cla_url(@cla)
  end

  test "should destroy cla" do
    assert_difference('Cla.count', -1) do
      delete cla_url(@cla)
    end

    assert_redirected_to clas_url
  end
end
