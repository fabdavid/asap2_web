require 'test_helper'

class GenesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gene = genes(:one)
  end

  test "should get index" do
    get genes_url
    assert_response :success
  end

  test "should get new" do
    get new_gene_url
    assert_response :success
  end

  test "should create gene" do
    assert_difference('Gene.count') do
      post genes_url, params: { gene: {  } }
    end

    assert_redirected_to gene_url(Gene.last)
  end

  test "should show gene" do
    get gene_url(@gene)
    assert_response :success
  end

  test "should get edit" do
    get edit_gene_url(@gene)
    assert_response :success
  end

  test "should update gene" do
    patch gene_url(@gene), params: { gene: {  } }
    assert_redirected_to gene_url(@gene)
  end

  test "should destroy gene" do
    assert_difference('Gene.count', -1) do
      delete gene_url(@gene)
    end

    assert_redirected_to genes_url
  end
end
