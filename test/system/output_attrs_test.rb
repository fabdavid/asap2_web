require "application_system_test_case"

class OutputAttrsTest < ApplicationSystemTestCase
  setup do
    @output_attr = output_attrs(:one)
  end

  test "visiting the index" do
    visit output_attrs_url
    assert_selector "h1", text: "Output Attrs"
  end

  test "creating a Output attr" do
    visit output_attrs_url
    click_on "New Output Attr"

    click_on "Create Output attr"

    assert_text "Output attr was successfully created"
    click_on "Back"
  end

  test "updating a Output attr" do
    visit output_attrs_url
    click_on "Edit", match: :first

    click_on "Update Output attr"

    assert_text "Output attr was successfully updated"
    click_on "Back"
  end

  test "destroying a Output attr" do
    visit output_attrs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Output attr was successfully destroyed"
  end
end
