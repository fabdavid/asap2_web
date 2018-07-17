require "application_system_test_case"

class FilterMethodsTest < ApplicationSystemTestCase
  setup do
    @filter_method = filter_methods(:one)
  end

  test "visiting the index" do
    visit filter_methods_url
    assert_selector "h1", text: "Filter Methods"
  end

  test "creating a Filter method" do
    visit filter_methods_url
    click_on "New Filter Method"

    click_on "Create Filter method"

    assert_text "Filter method was successfully created"
    click_on "Back"
  end

  test "updating a Filter method" do
    visit filter_methods_url
    click_on "Edit", match: :first

    click_on "Update Filter method"

    assert_text "Filter method was successfully updated"
    click_on "Back"
  end

  test "destroying a Filter method" do
    visit filter_methods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Filter method was successfully destroyed"
  end
end
