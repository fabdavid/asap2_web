require 'test_helper'

class GeneSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gene_set = gene_sets(:one)
  end

  test "should get index" do
    get gene_sets_url
    assert_response :success
  end

  test "should get new" do
    get new_gene_set_url
    assert_response :success
  end

  test "should create gene_set" do
    assert_difference('GeneSet.count') do
      post gene_sets_url, params: { gene_set: {  } }
    end

    assert_redirected_to gene_set_url(GeneSet.last)
  end

  test "should show gene_set" do
    get gene_set_url(@gene_set)
    assert_response :success
  end

  test "should get edit" do
    get edit_gene_set_url(@gene_set)
    assert_response :success
  end

  test "should update gene_set" do
    patch gene_set_url(@gene_set), params: { gene_set: {  } }
    assert_redirected_to gene_set_url(@gene_set)
  end

  test "should destroy gene_set" do
    assert_difference('GeneSet.count', -1) do
      delete gene_set_url(@gene_set)
    end

    assert_redirected_to gene_sets_url
  end
end
