require 'test_helper'

class GeneEnrichmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gene_enrichment = gene_enrichments(:one)
  end

  test "should get index" do
    get gene_enrichments_url
    assert_response :success
  end

  test "should get new" do
    get new_gene_enrichment_url
    assert_response :success
  end

  test "should create gene_enrichment" do
    assert_difference('GeneEnrichment.count') do
      post gene_enrichments_url, params: { gene_enrichment: {  } }
    end

    assert_redirected_to gene_enrichment_url(GeneEnrichment.last)
  end

  test "should show gene_enrichment" do
    get gene_enrichment_url(@gene_enrichment)
    assert_response :success
  end

  test "should get edit" do
    get edit_gene_enrichment_url(@gene_enrichment)
    assert_response :success
  end

  test "should update gene_enrichment" do
    patch gene_enrichment_url(@gene_enrichment), params: { gene_enrichment: {  } }
    assert_redirected_to gene_enrichment_url(@gene_enrichment)
  end

  test "should destroy gene_enrichment" do
    assert_difference('GeneEnrichment.count', -1) do
      delete gene_enrichment_url(@gene_enrichment)
    end

    assert_redirected_to gene_enrichments_url
  end
end
