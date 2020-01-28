require "application_system_test_case"

class TmpGenesTest < ApplicationSystemTestCase
  setup do
    @tmp_gene = tmp_genes(:one)
  end

  test "visiting the index" do
    visit tmp_genes_url
    assert_selector "h1", text: "Tmp Genes"
  end

  test "creating a Tmp gene" do
    visit tmp_genes_url
    click_on "New Tmp Gene"

    click_on "Create Tmp gene"

    assert_text "Tmp gene was successfully created"
    click_on "Back"
  end

  test "updating a Tmp gene" do
    visit tmp_genes_url
    click_on "Edit", match: :first

    click_on "Update Tmp gene"

    assert_text "Tmp gene was successfully updated"
    click_on "Back"
  end

  test "destroying a Tmp gene" do
    visit tmp_genes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tmp gene was successfully destroyed"
  end
end
