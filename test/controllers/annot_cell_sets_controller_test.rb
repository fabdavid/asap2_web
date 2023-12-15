require 'test_helper'

class AnnotCellSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @annot_cell_set = annot_cell_sets(:one)
  end

  test "should get index" do
    get annot_cell_sets_url
    assert_response :success
  end

  test "should get new" do
    get new_annot_cell_set_url
    assert_response :success
  end

  test "should create annot_cell_set" do
    assert_difference('AnnotCellSet.count') do
      post annot_cell_sets_url, params: { annot_cell_set: {  } }
    end

    assert_redirected_to annot_cell_set_url(AnnotCellSet.last)
  end

  test "should show annot_cell_set" do
    get annot_cell_set_url(@annot_cell_set)
    assert_response :success
  end

  test "should get edit" do
    get edit_annot_cell_set_url(@annot_cell_set)
    assert_response :success
  end

  test "should update annot_cell_set" do
    patch annot_cell_set_url(@annot_cell_set), params: { annot_cell_set: {  } }
    assert_redirected_to annot_cell_set_url(@annot_cell_set)
  end

  test "should destroy annot_cell_set" do
    assert_difference('AnnotCellSet.count', -1) do
      delete annot_cell_set_url(@annot_cell_set)
    end

    assert_redirected_to annot_cell_sets_url
  end
end
