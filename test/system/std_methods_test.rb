require "application_system_test_case"

class StdMethodsTest < ApplicationSystemTestCase
  setup do
    @std_method = std_methods(:one)
  end

  test "visiting the index" do
    visit std_methods_url
    assert_selector "h1", text: "Std Methods"
  end

  test "creating a Std method" do
    visit std_methods_url
    click_on "New Std Method"

    click_on "Create Std method"

    assert_text "Std method was successfully created"
    click_on "Back"
  end

  test "updating a Std method" do
    visit std_methods_url
    click_on "Edit", match: :first

    click_on "Update Std method"

    assert_text "Std method was successfully updated"
    click_on "Back"
  end

  test "destroying a Std method" do
    visit std_methods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Std method was successfully destroyed"
  end
end
