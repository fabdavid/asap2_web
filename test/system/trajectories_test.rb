require "application_system_test_case"

class TrajectoriesTest < ApplicationSystemTestCase
  setup do
    @trajectory = trajectories(:one)
  end

  test "visiting the index" do
    visit trajectories_url
    assert_selector "h1", text: "Trajectories"
  end

  test "creating a Trajectory" do
    visit trajectories_url
    click_on "New Trajectory"

    click_on "Create Trajectory"

    assert_text "Trajectory was successfully created"
    click_on "Back"
  end

  test "updating a Trajectory" do
    visit trajectories_url
    click_on "Edit", match: :first

    click_on "Update Trajectory"

    assert_text "Trajectory was successfully updated"
    click_on "Back"
  end

  test "destroying a Trajectory" do
    visit trajectories_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Trajectory was successfully destroyed"
  end
end
