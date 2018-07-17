require "application_system_test_case"

class SharesTest < ApplicationSystemTestCase
  setup do
    @share = shares(:one)
  end

  test "visiting the index" do
    visit shares_url
    assert_selector "h1", text: "Shares"
  end

  test "creating a Share" do
    visit shares_url
    click_on "New Share"

    click_on "Create Share"

    assert_text "Share was successfully created"
    click_on "Back"
  end

  test "updating a Share" do
    visit shares_url
    click_on "Edit", match: :first

    click_on "Update Share"

    assert_text "Share was successfully updated"
    click_on "Back"
  end

  test "destroying a Share" do
    visit shares_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Share was successfully destroyed"
  end
end
