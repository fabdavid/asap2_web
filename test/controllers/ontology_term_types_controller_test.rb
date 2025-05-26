require 'test_helper'

class OntologyTermTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ontology_term_type = ontology_term_types(:one)
  end

  test "should get index" do
    get ontology_term_types_url
    assert_response :success
  end

  test "should get new" do
    get new_ontology_term_type_url
    assert_response :success
  end

  test "should create ontology_term_type" do
    assert_difference('OntologyTermType.count') do
      post ontology_term_types_url, params: { ontology_term_type: {  } }
    end

    assert_redirected_to ontology_term_type_url(OntologyTermType.last)
  end

  test "should show ontology_term_type" do
    get ontology_term_type_url(@ontology_term_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_ontology_term_type_url(@ontology_term_type)
    assert_response :success
  end

  test "should update ontology_term_type" do
    patch ontology_term_type_url(@ontology_term_type), params: { ontology_term_type: {  } }
    assert_redirected_to ontology_term_type_url(@ontology_term_type)
  end

  test "should destroy ontology_term_type" do
    assert_difference('OntologyTermType.count', -1) do
      delete ontology_term_type_url(@ontology_term_type)
    end

    assert_redirected_to ontology_term_types_url
  end
end
