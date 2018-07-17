require "application_system_test_case"

class GeneEnrichmentsTest < ApplicationSystemTestCase
  setup do
    @gene_enrichment = gene_enrichments(:one)
  end

  test "visiting the index" do
    visit gene_enrichments_url
    assert_selector "h1", text: "Gene Enrichments"
  end

  test "creating a Gene enrichment" do
    visit gene_enrichments_url
    click_on "New Gene Enrichment"

    click_on "Create Gene enrichment"

    assert_text "Gene enrichment was successfully created"
    click_on "Back"
  end

  test "updating a Gene enrichment" do
    visit gene_enrichments_url
    click_on "Edit", match: :first

    click_on "Update Gene enrichment"

    assert_text "Gene enrichment was successfully updated"
    click_on "Back"
  end

  test "destroying a Gene enrichment" do
    visit gene_enrichments_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Gene enrichment was successfully destroyed"
  end
end
