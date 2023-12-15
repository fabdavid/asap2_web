require "application_system_test_case"

class CellOntologiesTest < ApplicationSystemTestCase
  setup do
    @cell_ontology = cell_ontologies(:one)
  end

  test "visiting the index" do
    visit cell_ontologies_url
    assert_selector "h1", text: "Cell Ontologies"
  end

  test "creating a Cell ontology" do
    visit cell_ontologies_url
    click_on "New Cell Ontology"

    click_on "Create Cell ontology"

    assert_text "Cell ontology was successfully created"
    click_on "Back"
  end

  test "updating a Cell ontology" do
    visit cell_ontologies_url
    click_on "Edit", match: :first

    click_on "Update Cell ontology"

    assert_text "Cell ontology was successfully updated"
    click_on "Back"
  end

  test "destroying a Cell ontology" do
    visit cell_ontologies_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cell ontology was successfully destroyed"
  end
end
