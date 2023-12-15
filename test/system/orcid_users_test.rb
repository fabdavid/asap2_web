require "application_system_test_case"

class OrcidUsersTest < ApplicationSystemTestCase
  setup do
    @orcid_user = orcid_users(:one)
  end

  test "visiting the index" do
    visit orcid_users_url
    assert_selector "h1", text: "Orcid Users"
  end

  test "creating a Orcid user" do
    visit orcid_users_url
    click_on "New Orcid User"

    click_on "Create Orcid user"

    assert_text "Orcid user was successfully created"
    click_on "Back"
  end

  test "updating a Orcid user" do
    visit orcid_users_url
    click_on "Edit", match: :first

    click_on "Update Orcid user"

    assert_text "Orcid user was successfully updated"
    click_on "Back"
  end

  test "destroying a Orcid user" do
    visit orcid_users_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Orcid user was successfully destroyed"
  end
end
