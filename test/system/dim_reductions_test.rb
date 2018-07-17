require "application_system_test_case"

class DimReductionsTest < ApplicationSystemTestCase
  setup do
    @dim_reduction = dim_reductions(:one)
  end

  test "visiting the index" do
    visit dim_reductions_url
    assert_selector "h1", text: "Dim Reductions"
  end

  test "creating a Dim reduction" do
    visit dim_reductions_url
    click_on "New Dim Reduction"

    click_on "Create Dim reduction"

    assert_text "Dim reduction was successfully created"
    click_on "Back"
  end

  test "updating a Dim reduction" do
    visit dim_reductions_url
    click_on "Edit", match: :first

    click_on "Update Dim reduction"

    assert_text "Dim reduction was successfully updated"
    click_on "Back"
  end

  test "destroying a Dim reduction" do
    visit dim_reductions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Dim reduction was successfully destroyed"
  end
end
