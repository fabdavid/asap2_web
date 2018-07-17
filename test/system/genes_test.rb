require "application_system_test_case"

class GenesTest < ApplicationSystemTestCase
  setup do
    @gene = genes(:one)
  end

  test "visiting the index" do
    visit genes_url
    assert_selector "h1", text: "Genes"
  end

  test "creating a Gene" do
    visit genes_url
    click_on "New Gene"

    click_on "Create Gene"

    assert_text "Gene was successfully created"
    click_on "Back"
  end

  test "updating a Gene" do
    visit genes_url
    click_on "Edit", match: :first

    click_on "Update Gene"

    assert_text "Gene was successfully updated"
    click_on "Back"
  end

  test "destroying a Gene" do
    visit genes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Gene was successfully destroyed"
  end
end
