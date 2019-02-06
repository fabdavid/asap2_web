require "application_system_test_case"

class GeneFilteringsTest < ApplicationSystemTestCase
  setup do
    @gene_filtering = gene_filterings(:one)
  end

  test "visiting the index" do
    visit gene_filterings_url
    assert_selector "h1", text: "Gene Filterings"
  end

  test "creating a Gene filtering" do
    visit gene_filterings_url
    click_on "New Gene Filtering"

    click_on "Create Gene filtering"

    assert_text "Gene filtering was successfully created"
    click_on "Back"
  end

  test "updating a Gene filtering" do
    visit gene_filterings_url
    click_on "Edit", match: :first

    click_on "Update Gene filtering"

    assert_text "Gene filtering was successfully updated"
    click_on "Back"
  end

  test "destroying a Gene filtering" do
    visit gene_filterings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Gene filtering was successfully destroyed"
  end
end
