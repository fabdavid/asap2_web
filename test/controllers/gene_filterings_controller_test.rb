require 'test_helper'

class GeneFilteringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @gene_filtering = gene_filterings(:one)
  end

  test "should get index" do
    get gene_filterings_url
    assert_response :success
  end

  test "should get new" do
    get new_gene_filtering_url
    assert_response :success
  end

  test "should create gene_filtering" do
    assert_difference('GeneFiltering.count') do
      post gene_filterings_url, params: { gene_filtering: {  } }
    end

    assert_redirected_to gene_filtering_url(GeneFiltering.last)
  end

  test "should show gene_filtering" do
    get gene_filtering_url(@gene_filtering)
    assert_response :success
  end

  test "should get edit" do
    get edit_gene_filtering_url(@gene_filtering)
    assert_response :success
  end

  test "should update gene_filtering" do
    patch gene_filtering_url(@gene_filtering), params: { gene_filtering: {  } }
    assert_redirected_to gene_filtering_url(@gene_filtering)
  end

  test "should destroy gene_filtering" do
    assert_difference('GeneFiltering.count', -1) do
      delete gene_filtering_url(@gene_filtering)
    end

    assert_redirected_to gene_filterings_url
  end
end
