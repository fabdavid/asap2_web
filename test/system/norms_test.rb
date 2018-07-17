require "application_system_test_case"

class NormsTest < ApplicationSystemTestCase
  setup do
    @norm = norms(:one)
  end

  test "visiting the index" do
    visit norms_url
    assert_selector "h1", text: "Norms"
  end

  test "creating a Norm" do
    visit norms_url
    click_on "New Norm"

    click_on "Create Norm"

    assert_text "Norm was successfully created"
    click_on "Back"
  end

  test "updating a Norm" do
    visit norms_url
    click_on "Edit", match: :first

    click_on "Update Norm"

    assert_text "Norm was successfully updated"
    click_on "Back"
  end

  test "destroying a Norm" do
    visit norms_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Norm was successfully destroyed"
  end
end
