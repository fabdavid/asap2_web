require "application_system_test_case"

class SelectionsTest < ApplicationSystemTestCase
  setup do
    @selection = selections(:one)
  end

  test "visiting the index" do
    visit selections_url
    assert_selector "h1", text: "Selections"
  end

  test "creating a Selection" do
    visit selections_url
    click_on "New Selection"

    click_on "Create Selection"

    assert_text "Selection was successfully created"
    click_on "Back"
  end

  test "updating a Selection" do
    visit selections_url
    click_on "Edit", match: :first

    click_on "Update Selection"

    assert_text "Selection was successfully updated"
    click_on "Back"
  end

  test "destroying a Selection" do
    visit selections_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Selection was successfully destroyed"
  end
end
