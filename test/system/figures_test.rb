require "application_system_test_case"

class FiguresTest < ApplicationSystemTestCase
  setup do
    @figure = figures(:one)
  end

  test "visiting the index" do
    visit figures_url
    assert_selector "h1", text: "Figures"
  end

  test "creating a Figure" do
    visit figures_url
    click_on "New Figure"

    click_on "Create Figure"

    assert_text "Figure was successfully created"
    click_on "Back"
  end

  test "updating a Figure" do
    visit figures_url
    click_on "Edit", match: :first

    click_on "Update Figure"

    assert_text "Figure was successfully updated"
    click_on "Back"
  end

  test "destroying a Figure" do
    visit figures_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Figure was successfully destroyed"
  end
end
