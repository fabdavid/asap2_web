require "application_system_test_case"

class AttrOutputsTest < ApplicationSystemTestCase
  setup do
    @attr_output = attr_outputs(:one)
  end

  test "visiting the index" do
    visit attr_outputs_url
    assert_selector "h1", text: "Attr Outputs"
  end

  test "creating a Attr output" do
    visit attr_outputs_url
    click_on "New Attr Output"

    click_on "Create Attr output"

    assert_text "Attr output was successfully created"
    click_on "Back"
  end

  test "updating a Attr output" do
    visit attr_outputs_url
    click_on "Edit", match: :first

    click_on "Update Attr output"

    assert_text "Attr output was successfully updated"
    click_on "Back"
  end

  test "destroying a Attr output" do
    visit attr_outputs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Attr output was successfully destroyed"
  end
end
