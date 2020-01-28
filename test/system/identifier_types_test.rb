require "application_system_test_case"

class IdentifierTypesTest < ApplicationSystemTestCase
  setup do
    @identifier_type = identifier_types(:one)
  end

  test "visiting the index" do
    visit identifier_types_url
    assert_selector "h1", text: "Identifier Types"
  end

  test "creating a Identifier type" do
    visit identifier_types_url
    click_on "New Identifier Type"

    click_on "Create Identifier type"

    assert_text "Identifier type was successfully created"
    click_on "Back"
  end

  test "updating a Identifier type" do
    visit identifier_types_url
    click_on "Edit", match: :first

    click_on "Update Identifier type"

    assert_text "Identifier type was successfully updated"
    click_on "Back"
  end

  test "destroying a Identifier type" do
    visit identifier_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Identifier type was successfully destroyed"
  end
end
