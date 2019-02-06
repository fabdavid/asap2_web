require "application_system_test_case"

class ActiveRunsTest < ApplicationSystemTestCase
  setup do
    @active_run = active_runs(:one)
  end

  test "visiting the index" do
    visit active_runs_url
    assert_selector "h1", text: "Active Runs"
  end

  test "creating a Active run" do
    visit active_runs_url
    click_on "New Active Run"

    click_on "Create Active run"

    assert_text "Active run was successfully created"
    click_on "Back"
  end

  test "updating a Active run" do
    visit active_runs_url
    click_on "Edit", match: :first

    click_on "Update Active run"

    assert_text "Active run was successfully updated"
    click_on "Back"
  end

  test "destroying a Active run" do
    visit active_runs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Active run was successfully destroyed"
  end
end
