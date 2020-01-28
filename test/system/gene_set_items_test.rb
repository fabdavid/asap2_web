require "application_system_test_case"

class GeneSetItemsTest < ApplicationSystemTestCase
  setup do
    @gene_set_item = gene_set_items(:one)
  end

  test "visiting the index" do
    visit gene_set_items_url
    assert_selector "h1", text: "Gene Set Items"
  end

  test "creating a Gene set item" do
    visit gene_set_items_url
    click_on "New Gene Set Item"

    click_on "Create Gene set item"

    assert_text "Gene set item was successfully created"
    click_on "Back"
  end

  test "updating a Gene set item" do
    visit gene_set_items_url
    click_on "Edit", match: :first

    click_on "Update Gene set item"

    assert_text "Gene set item was successfully updated"
    click_on "Back"
  end

  test "destroying a Gene set item" do
    visit gene_set_items_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Gene set item was successfully destroyed"
  end
end
