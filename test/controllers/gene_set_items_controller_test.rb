require 'test_helper'

class GeneSetItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gene_set_item = gene_set_items(:one)
  end

  test "should get index" do
    get gene_set_items_url
    assert_response :success
  end

  test "should get new" do
    get new_gene_set_item_url
    assert_response :success
  end

  test "should create gene_set_item" do
    assert_difference('GeneSetItem.count') do
      post gene_set_items_url, params: { gene_set_item: {  } }
    end

    assert_redirected_to gene_set_item_url(GeneSetItem.last)
  end

  test "should show gene_set_item" do
    get gene_set_item_url(@gene_set_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_gene_set_item_url(@gene_set_item)
    assert_response :success
  end

  test "should update gene_set_item" do
    patch gene_set_item_url(@gene_set_item), params: { gene_set_item: {  } }
    assert_redirected_to gene_set_item_url(@gene_set_item)
  end

  test "should destroy gene_set_item" do
    assert_difference('GeneSetItem.count', -1) do
      delete gene_set_item_url(@gene_set_item)
    end

    assert_redirected_to gene_set_items_url
  end
end
