require "application_system_test_case"

class HcaoTermsTest < ApplicationSystemTestCase
  setup do
    @hcao_term = hcao_terms(:one)
  end

  test "visiting the index" do
    visit hcao_terms_url
    assert_selector "h1", text: "Hcao Terms"
  end

  test "creating a Hcao term" do
    visit hcao_terms_url
    click_on "New Hcao Term"

    click_on "Create Hcao term"

    assert_text "Hcao term was successfully created"
    click_on "Back"
  end

  test "updating a Hcao term" do
    visit hcao_terms_url
    click_on "Edit", match: :first

    click_on "Update Hcao term"

    assert_text "Hcao term was successfully updated"
    click_on "Back"
  end

  test "destroying a Hcao term" do
    visit hcao_terms_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Hcao term was successfully destroyed"
  end
end
