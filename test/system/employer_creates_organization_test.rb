require "application_system_test_case"

class EmployerCreatesOrganizationTest < ApplicationSystemTestCase
  test "employer creates organization and sees dashboard" do
    # Visit the homepage
    visit root_path

    # Click "Create Organization" link
    click_on "Create Organization"

    # Fill in organization name with unique name to avoid test pollution
    unique_org_name = "Acme Corp #{Time.now.to_i}"
    fill_in "Name", with: unique_org_name

    # Submit form
    click_button "Create Organization"

    # Should see organization dashboard (with explicit wait for Turbo navigation)
    assert_selector "h1", text: "#{unique_org_name} Dashboard", wait: 5
    assert_text "Organization created successfully"
  end

  test "employer creates questionnaire from dashboard" do
    # Create organization first
    organization = organizations(:one)

    # Visit organization dashboard
    visit organization_path(organization.unique_token)

    # Click "Create Questionnaire" button
    click_on "Create Questionnaire"

    # Fill in questionnaire details
    fill_in "Title", with: "How to Work With Me"
    fill_in "Description", with: "Tell us about your working preferences"

    # Submit form
    click_button "Create Questionnaire"

    # Should be redirected to questionnaire configuration page
    assert_selector "h1", text: "Configure Questionnaire"
    assert_text "Questionnaire created successfully"
  end
end
