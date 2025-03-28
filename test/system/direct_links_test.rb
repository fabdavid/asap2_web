require "application_system_test_case"

class DirectLinksTest < ApplicationSystemTestCase
  setup do
    @direct_link = direct_links(:one)
  end

  test "visiting the index" do
    visit direct_links_url
    assert_selector "h1", text: "Direct Links"
  end

  test "creating a Direct link" do
    visit direct_links_url
    click_on "New Direct Link"

    click_on "Create Direct link"

    assert_text "Direct link was successfully created"
    click_on "Back"
  end

  test "updating a Direct link" do
    visit direct_links_url
    click_on "Edit", match: :first

    click_on "Update Direct link"

    assert_text "Direct link was successfully updated"
    click_on "Back"
  end

  test "destroying a Direct link" do
    visit direct_links_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Direct link was successfully destroyed"
  end
end
