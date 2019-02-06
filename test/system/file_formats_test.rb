require "application_system_test_case"

class FileFormatsTest < ApplicationSystemTestCase
  setup do
    @file_format = file_formats(:one)
  end

  test "visiting the index" do
    visit file_formats_url
    assert_selector "h1", text: "File Formats"
  end

  test "creating a File format" do
    visit file_formats_url
    click_on "New File Format"

    click_on "Create File format"

    assert_text "File format was successfully created"
    click_on "Back"
  end

  test "updating a File format" do
    visit file_formats_url
    click_on "Edit", match: :first

    click_on "Update File format"

    assert_text "File format was successfully updated"
    click_on "Back"
  end

  test "destroying a File format" do
    visit file_formats_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "File format was successfully destroyed"
  end
end
