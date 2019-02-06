require "application_system_test_case"

class CovariatesTest < ApplicationSystemTestCase
  setup do
    @covariate = covariates(:one)
  end

  test "visiting the index" do
    visit covariates_url
    assert_selector "h1", text: "Covariates"
  end

  test "creating a Covariate" do
    visit covariates_url
    click_on "New Covariate"

    click_on "Create Covariate"

    assert_text "Covariate was successfully created"
    click_on "Back"
  end

  test "updating a Covariate" do
    visit covariates_url
    click_on "Edit", match: :first

    click_on "Update Covariate"

    assert_text "Covariate was successfully updated"
    click_on "Back"
  end

  test "destroying a Covariate" do
    visit covariates_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Covariate was successfully destroyed"
  end
end
