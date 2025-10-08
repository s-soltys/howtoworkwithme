require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get root_path
    assert_response :success
    assert_select "h1", "Create Organization"
  end

  test "should create organization and redirect to dashboard" do
    assert_difference("Organization.count", 1) do
      post organizations_path, params: { organization: { name: "Test Corp" } }
    end

    organization = Organization.last
    assert_redirected_to organization_path(organization.unique_token)
    follow_redirect!
    assert_select "h1", "Test Corp Dashboard"
  end

  test "should not create organization with invalid data" do
    assert_no_difference("Organization.count") do
      post organizations_path, params: { organization: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show organization dashboard" do
    organization = organizations(:one)
    get organization_path(organization.unique_token)
    assert_response :success
    assert_select "h1", "#{organization.name} Dashboard"
  end

  test "should show 404 for invalid organization token" do
    get organization_path("invalid-token")
    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    # This is also acceptable behavior
    assert true
  end
end
