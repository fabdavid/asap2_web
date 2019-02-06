require "application_system_test_case"

class DelRunsTest < ApplicationSystemTestCase
  setup do
    @del_run = del_runs(:one)
  end

  test "visiting the index" do
    visit del_runs_url
    assert_selector "h1", text: "Del Runs"
  end

  test "creating a Del run" do
    visit del_runs_url
    click_on "New Del Run"

    click_on "Create Del run"

    assert_text "Del run was successfully created"
    click_on "Back"
  end

  test "updating a Del run" do
    visit del_runs_url
    click_on "Edit", match: :first

    click_on "Update Del run"

    assert_text "Del run was successfully updated"
    click_on "Back"
  end

  test "destroying a Del run" do
    visit del_runs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Del run was successfully destroyed"
  end
end
