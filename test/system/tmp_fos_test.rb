require "application_system_test_case"

class TmpFosTest < ApplicationSystemTestCase
  setup do
    @tmp_fo = tmp_fos(:one)
  end

  test "visiting the index" do
    visit tmp_fos_url
    assert_selector "h1", text: "Tmp Fos"
  end

  test "creating a Tmp fo" do
    visit tmp_fos_url
    click_on "New Tmp Fo"

    click_on "Create Tmp fo"

    assert_text "Tmp fo was successfully created"
    click_on "Back"
  end

  test "updating a Tmp fo" do
    visit tmp_fos_url
    click_on "Edit", match: :first

    click_on "Update Tmp fo"

    assert_text "Tmp fo was successfully updated"
    click_on "Back"
  end

  test "destroying a Tmp fo" do
    visit tmp_fos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tmp fo was successfully destroyed"
  end
end
