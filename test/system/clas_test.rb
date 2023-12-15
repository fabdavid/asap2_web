require "application_system_test_case"

class ClasTest < ApplicationSystemTestCase
  setup do
    @cla = clas(:one)
  end

  test "visiting the index" do
    visit clas_url
    assert_selector "h1", text: "Clas"
  end

  test "creating a Cla" do
    visit clas_url
    click_on "New Cla"

    click_on "Create Cla"

    assert_text "Cla was successfully created"
    click_on "Back"
  end

  test "updating a Cla" do
    visit clas_url
    click_on "Edit", match: :first

    click_on "Update Cla"

    assert_text "Cla was successfully updated"
    click_on "Back"
  end

  test "destroying a Cla" do
    visit clas_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cla was successfully destroyed"
  end
end
