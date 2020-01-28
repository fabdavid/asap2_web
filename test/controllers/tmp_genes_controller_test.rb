require 'test_helper'

class TmpGenesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tmp_gene = tmp_genes(:one)
  end

  test "should get index" do
    get tmp_genes_url
    assert_response :success
  end

  test "should get new" do
    get new_tmp_gene_url
    assert_response :success
  end

  test "should create tmp_gene" do
    assert_difference('TmpGene.count') do
      post tmp_genes_url, params: { tmp_gene: {  } }
    end

    assert_redirected_to tmp_gene_url(TmpGene.last)
  end

  test "should show tmp_gene" do
    get tmp_gene_url(@tmp_gene)
    assert_response :success
  end

  test "should get edit" do
    get edit_tmp_gene_url(@tmp_gene)
    assert_response :success
  end

  test "should update tmp_gene" do
    patch tmp_gene_url(@tmp_gene), params: { tmp_gene: {  } }
    assert_redirected_to tmp_gene_url(@tmp_gene)
  end

  test "should destroy tmp_gene" do
    assert_difference('TmpGene.count', -1) do
      delete tmp_gene_url(@tmp_gene)
    end

    assert_redirected_to tmp_genes_url
  end
end
