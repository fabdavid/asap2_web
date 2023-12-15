require 'test_helper'

class CellSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cell_set = cell_sets(:one)
  end

  test "should get index" do
    get cell_sets_url
    assert_response :success
  end

  test "should get new" do
    get new_cell_set_url
    assert_response :success
  end

  test "should create cell_set" do
    assert_difference('CellSet.count') do
      post cell_sets_url, params: { cell_set: {  } }
    end

    assert_redirected_to cell_set_url(CellSet.last)
  end

  test "should show cell_set" do
    get cell_set_url(@cell_set)
    assert_response :success
  end

  test "should get edit" do
    get edit_cell_set_url(@cell_set)
    assert_response :success
  end

  test "should update cell_set" do
    patch cell_set_url(@cell_set), params: { cell_set: {  } }
    assert_redirected_to cell_set_url(@cell_set)
  end

  test "should destroy cell_set" do
    assert_difference('CellSet.count', -1) do
      delete cell_set_url(@cell_set)
    end

    assert_redirected_to cell_sets_url
  end
end
