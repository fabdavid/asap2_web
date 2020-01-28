require "application_system_test_case"

class SampleIdentifiersTest < ApplicationSystemTestCase
  setup do
    @sample_identifier = sample_identifiers(:one)
  end

  test "visiting the index" do
    visit sample_identifiers_url
    assert_selector "h1", text: "Sample Identifiers"
  end

  test "creating a Sample identifier" do
    visit sample_identifiers_url
    click_on "New Sample Identifier"

    click_on "Create Sample identifier"

    assert_text "Sample identifier was successfully created"
    click_on "Back"
  end

  test "updating a Sample identifier" do
    visit sample_identifiers_url
    click_on "Edit", match: :first

    click_on "Update Sample identifier"

    assert_text "Sample identifier was successfully updated"
    click_on "Back"
  end

  test "destroying a Sample identifier" do
    visit sample_identifiers_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Sample identifier was successfully destroyed"
  end
end
