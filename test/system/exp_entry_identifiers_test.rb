require "application_system_test_case"

class ExpEntryIdentifiersTest < ApplicationSystemTestCase
  setup do
    @exp_entry_identifier = exp_entry_identifiers(:one)
  end

  test "visiting the index" do
    visit exp_entry_identifiers_url
    assert_selector "h1", text: "Exp Entry Identifiers"
  end

  test "creating a Exp entry identifier" do
    visit exp_entry_identifiers_url
    click_on "New Exp Entry Identifier"

    click_on "Create Exp entry identifier"

    assert_text "Exp entry identifier was successfully created"
    click_on "Back"
  end

  test "updating a Exp entry identifier" do
    visit exp_entry_identifiers_url
    click_on "Edit", match: :first

    click_on "Update Exp entry identifier"

    assert_text "Exp entry identifier was successfully updated"
    click_on "Back"
  end

  test "destroying a Exp entry identifier" do
    visit exp_entry_identifiers_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Exp entry identifier was successfully destroyed"
  end
end
