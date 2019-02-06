require 'test_helper'

class CellFilteringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cell_filtering = cell_filterings(:one)
  end

  test "should get index" do
    get cell_filterings_url
    assert_response :success
  end

  test "should get new" do
    get new_cell_filtering_url
    assert_response :success
  end

  test "should create cell_filtering" do
    assert_difference('CellFiltering.count') do
      post cell_filterings_url, params: { cell_filtering: {  } }
    end

    assert_redirected_to cell_filtering_url(CellFiltering.last)
  end

  test "should show cell_filtering" do
    get cell_filtering_url(@cell_filtering)
    assert_response :success
  end

  test "should get edit" do
    get edit_cell_filtering_url(@cell_filtering)
    assert_response :success
  end

  test "should update cell_filtering" do
    patch cell_filtering_url(@cell_filtering), params: { cell_filtering: {  } }
    assert_redirected_to cell_filtering_url(@cell_filtering)
  end

  test "should destroy cell_filtering" do
    assert_difference('CellFiltering.count', -1) do
      delete cell_filtering_url(@cell_filtering)
    end

    assert_redirected_to cell_filterings_url
  end
end
