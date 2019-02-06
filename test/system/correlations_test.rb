require "application_system_test_case"

class CorrelationsTest < ApplicationSystemTestCase
  setup do
    @correlation = correlations(:one)
  end

  test "visiting the index" do
    visit correlations_url
    assert_selector "h1", text: "Correlations"
  end

  test "creating a Correlation" do
    visit correlations_url
    click_on "New Correlation"

    click_on "Create Correlation"

    assert_text "Correlation was successfully created"
    click_on "Back"
  end

  test "updating a Correlation" do
    visit correlations_url
    click_on "Edit", match: :first

    click_on "Update Correlation"

    assert_text "Correlation was successfully updated"
    click_on "Back"
  end

  test "destroying a Correlation" do
    visit correlations_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Correlation was successfully destroyed"
  end
end
