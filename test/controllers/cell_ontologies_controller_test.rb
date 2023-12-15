require 'test_helper'

class CellOntologiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cell_ontology = cell_ontologies(:one)
  end

  test "should get index" do
    get cell_ontologies_url
    assert_response :success
  end

  test "should get new" do
    get new_cell_ontology_url
    assert_response :success
  end

  test "should create cell_ontology" do
    assert_difference('CellOntology.count') do
      post cell_ontologies_url, params: { cell_ontology: {  } }
    end

    assert_redirected_to cell_ontology_url(CellOntology.last)
  end

  test "should show cell_ontology" do
    get cell_ontology_url(@cell_ontology)
    assert_response :success
  end

  test "should get edit" do
    get edit_cell_ontology_url(@cell_ontology)
    assert_response :success
  end

  test "should update cell_ontology" do
    patch cell_ontology_url(@cell_ontology), params: { cell_ontology: {  } }
    assert_redirected_to cell_ontology_url(@cell_ontology)
  end

  test "should destroy cell_ontology" do
    assert_difference('CellOntology.count', -1) do
      delete cell_ontology_url(@cell_ontology)
    end

    assert_redirected_to cell_ontologies_url
  end
end
