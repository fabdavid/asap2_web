require "application_system_test_case"

class GeneSetsTest < ApplicationSystemTestCase
  setup do
    @gene_set = gene_sets(:one)
  end

  test "visiting the index" do
    visit gene_sets_url
    assert_selector "h1", text: "Gene Sets"
  end

  test "creating a Gene set" do
    visit gene_sets_url
    click_on "New Gene Set"

    click_on "Create Gene set"

    assert_text "Gene set was successfully created"
    click_on "Back"
  end

  test "updating a Gene set" do
    visit gene_sets_url
    click_on "Edit", match: :first

    click_on "Update Gene set"

    assert_text "Gene set was successfully updated"
    click_on "Back"
  end

  test "destroying a Gene set" do
    visit gene_sets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Gene set was successfully destroyed"
  end
end
