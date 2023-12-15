require "application_system_test_case"

class DataClassesTest < ApplicationSystemTestCase
  setup do
    @data_class = data_classes(:one)
  end

  test "visiting the index" do
    visit data_classes_url
    assert_selector "h1", text: "Data Classes"
  end

  test "creating a Data class" do
    visit data_classes_url
    click_on "New Data Class"

    click_on "Create Data class"

    assert_text "Data class was successfully created"
    click_on "Back"
  end

  test "updating a Data class" do
    visit data_classes_url
    click_on "Edit", match: :first

    click_on "Update Data class"

    assert_text "Data class was successfully updated"
    click_on "Back"
  end

  test "destroying a Data class" do
    visit data_classes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Data class was successfully destroyed"
  end
end
