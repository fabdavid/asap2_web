require "application_system_test_case"

class UploadTypesTest < ApplicationSystemTestCase
  setup do
    @upload_type = upload_types(:one)
  end

  test "visiting the index" do
    visit upload_types_url
    assert_selector "h1", text: "Upload Types"
  end

  test "creating a Upload type" do
    visit upload_types_url
    click_on "New Upload Type"

    click_on "Create Upload type"

    assert_text "Upload type was successfully created"
    click_on "Back"
  end

  test "updating a Upload type" do
    visit upload_types_url
    click_on "Edit", match: :first

    click_on "Update Upload type"

    assert_text "Upload type was successfully updated"
    click_on "Back"
  end

  test "destroying a Upload type" do
    visit upload_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Upload type was successfully destroyed"
  end
end
