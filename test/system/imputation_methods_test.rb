require "application_system_test_case"

class ImputationMethodsTest < ApplicationSystemTestCase
  setup do
    @imputation_method = imputation_methods(:one)
  end

  test "visiting the index" do
    visit imputation_methods_url
    assert_selector "h1", text: "Imputation Methods"
  end

  test "creating a Imputation method" do
    visit imputation_methods_url
    click_on "New Imputation Method"

    click_on "Create Imputation method"

    assert_text "Imputation method was successfully created"
    click_on "Back"
  end

  test "updating a Imputation method" do
    visit imputation_methods_url
    click_on "Edit", match: :first

    click_on "Update Imputation method"

    assert_text "Imputation method was successfully updated"
    click_on "Back"
  end

  test "destroying a Imputation method" do
    visit imputation_methods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Imputation method was successfully destroyed"
  end
end
