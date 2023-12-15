require "application_system_test_case"

class CellOntologyTermsTest < ApplicationSystemTestCase
  setup do
    @cell_ontology_term = cell_ontology_terms(:one)
  end

  test "visiting the index" do
    visit cell_ontology_terms_url
    assert_selector "h1", text: "Cell Ontology Terms"
  end

  test "creating a Cell ontology term" do
    visit cell_ontology_terms_url
    click_on "New Cell Ontology Term"

    click_on "Create Cell ontology term"

    assert_text "Cell ontology term was successfully created"
    click_on "Back"
  end

  test "updating a Cell ontology term" do
    visit cell_ontology_terms_url
    click_on "Edit", match: :first

    click_on "Update Cell ontology term"

    assert_text "Cell ontology term was successfully updated"
    click_on "Back"
  end

  test "destroying a Cell ontology term" do
    visit cell_ontology_terms_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cell ontology term was successfully destroyed"
  end
end
