require "application_system_test_case"

class OntologyTermTypesTest < ApplicationSystemTestCase
  setup do
    @ontology_term_type = ontology_term_types(:one)
  end

  test "visiting the index" do
    visit ontology_term_types_url
    assert_selector "h1", text: "Ontology Term Types"
  end

  test "creating a Ontology term type" do
    visit ontology_term_types_url
    click_on "New Ontology Term Type"

    click_on "Create Ontology term type"

    assert_text "Ontology term type was successfully created"
    click_on "Back"
  end

  test "updating a Ontology term type" do
    visit ontology_term_types_url
    click_on "Edit", match: :first

    click_on "Update Ontology term type"

    assert_text "Ontology term type was successfully updated"
    click_on "Back"
  end

  test "destroying a Ontology term type" do
    visit ontology_term_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ontology term type was successfully destroyed"
  end
end
