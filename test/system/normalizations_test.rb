require "application_system_test_case"

class NormalizationsTest < ApplicationSystemTestCase
  setup do
    @normalization = normalizations(:one)
  end

  test "visiting the index" do
    visit normalizations_url
    assert_selector "h1", text: "Normalizations"
  end

  test "creating a Normalization" do
    visit normalizations_url
    click_on "New Normalization"

    click_on "Create Normalization"

    assert_text "Normalization was successfully created"
    click_on "Back"
  end

  test "updating a Normalization" do
    visit normalizations_url
    click_on "Edit", match: :first

    click_on "Update Normalization"

    assert_text "Normalization was successfully updated"
    click_on "Back"
  end

  test "destroying a Normalization" do
    visit normalizations_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Normalization was successfully destroyed"
  end
end
