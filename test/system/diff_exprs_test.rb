require "application_system_test_case"

class DiffExprsTest < ApplicationSystemTestCase
  setup do
    @diff_expr = diff_exprs(:one)
  end

  test "visiting the index" do
    visit diff_exprs_url
    assert_selector "h1", text: "Diff Exprs"
  end

  test "creating a Diff expr" do
    visit diff_exprs_url
    click_on "New Diff Expr"

    click_on "Create Diff expr"

    assert_text "Diff expr was successfully created"
    click_on "Back"
  end

  test "updating a Diff expr" do
    visit diff_exprs_url
    click_on "Edit", match: :first

    click_on "Update Diff expr"

    assert_text "Diff expr was successfully updated"
    click_on "Back"
  end

  test "destroying a Diff expr" do
    visit diff_exprs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Diff expr was successfully destroyed"
  end
end
