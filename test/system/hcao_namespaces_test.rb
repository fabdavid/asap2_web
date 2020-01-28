require "application_system_test_case"

class HcaoNamespacesTest < ApplicationSystemTestCase
  setup do
    @hcao_namespace = hcao_namespaces(:one)
  end

  test "visiting the index" do
    visit hcao_namespaces_url
    assert_selector "h1", text: "Hcao Namespaces"
  end

  test "creating a Hcao namespace" do
    visit hcao_namespaces_url
    click_on "New Hcao Namespace"

    click_on "Create Hcao namespace"

    assert_text "Hcao namespace was successfully created"
    click_on "Back"
  end

  test "updating a Hcao namespace" do
    visit hcao_namespaces_url
    click_on "Edit", match: :first

    click_on "Update Hcao namespace"

    assert_text "Hcao namespace was successfully updated"
    click_on "Back"
  end

  test "destroying a Hcao namespace" do
    visit hcao_namespaces_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Hcao namespace was successfully destroyed"
  end
end
