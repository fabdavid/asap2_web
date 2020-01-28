require "application_system_test_case"

class EnsemblSubdomainsTest < ApplicationSystemTestCase
  setup do
    @ensembl_subdomain = ensembl_subdomains(:one)
  end

  test "visiting the index" do
    visit ensembl_subdomains_url
    assert_selector "h1", text: "Ensembl Subdomains"
  end

  test "creating a Ensembl subdomain" do
    visit ensembl_subdomains_url
    click_on "New Ensembl Subdomain"

    click_on "Create Ensembl subdomain"

    assert_text "Ensembl subdomain was successfully created"
    click_on "Back"
  end

  test "updating a Ensembl subdomain" do
    visit ensembl_subdomains_url
    click_on "Edit", match: :first

    click_on "Update Ensembl subdomain"

    assert_text "Ensembl subdomain was successfully updated"
    click_on "Back"
  end

  test "destroying a Ensembl subdomain" do
    visit ensembl_subdomains_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ensembl subdomain was successfully destroyed"
  end
end
