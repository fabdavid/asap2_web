require "application_system_test_case"

class ClaVotesTest < ApplicationSystemTestCase
  setup do
    @cla_vote = cla_votes(:one)
  end

  test "visiting the index" do
    visit cla_votes_url
    assert_selector "h1", text: "Cla Votes"
  end

  test "creating a Cla vote" do
    visit cla_votes_url
    click_on "New Cla Vote"

    click_on "Create Cla vote"

    assert_text "Cla vote was successfully created"
    click_on "Back"
  end

  test "updating a Cla vote" do
    visit cla_votes_url
    click_on "Edit", match: :first

    click_on "Update Cla vote"

    assert_text "Cla vote was successfully updated"
    click_on "Back"
  end

  test "destroying a Cla vote" do
    visit cla_votes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Cla vote was successfully destroyed"
  end
end
