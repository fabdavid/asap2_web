require 'test_helper'

class CellOntologyTermsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cell_ontology_term = cell_ontology_terms(:one)
  end

  test "should get index" do
    get cell_ontology_terms_url
    assert_response :success
  end

  test "should get new" do
    get new_cell_ontology_term_url
    assert_response :success
  end

  test "should create cell_ontology_term" do
    assert_difference('CellOntologyTerm.count') do
      post cell_ontology_terms_url, params: { cell_ontology_term: {  } }
    end

    assert_redirected_to cell_ontology_term_url(CellOntologyTerm.last)
  end

  test "should show cell_ontology_term" do
    get cell_ontology_term_url(@cell_ontology_term)
    assert_response :success
  end

  test "should get edit" do
    get edit_cell_ontology_term_url(@cell_ontology_term)
    assert_response :success
  end

  test "should update cell_ontology_term" do
    patch cell_ontology_term_url(@cell_ontology_term), params: { cell_ontology_term: {  } }
    assert_redirected_to cell_ontology_term_url(@cell_ontology_term)
  end

  test "should destroy cell_ontology_term" do
    assert_difference('CellOntologyTerm.count', -1) do
      delete cell_ontology_term_url(@cell_ontology_term)
    end

    assert_redirected_to cell_ontology_terms_url
  end
end
