require "application_system_test_case"

class StdRunsTest < ApplicationSystemTestCase
  setup do
    @std_run = std_runs(:one)
  end

  test "visiting the index" do
    visit std_runs_url
    assert_selector "h1", text: "Std Runs"
  end

  test "creating a Std run" do
    visit std_runs_url
    click_on "New Std Run"

    click_on "Create Std run"

    assert_text "Std run was successfully created"
    click_on "Back"
  end

  test "updating a Std run" do
    visit std_runs_url
    click_on "Edit", match: :first

    click_on "Update Std run"

    assert_text "Std run was successfully updated"
    click_on "Back"
  end

  test "destroying a Std run" do
    visit std_runs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Std run was successfully destroyed"
  end
end
