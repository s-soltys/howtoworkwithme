require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!(status: "submitted", submitted_at: Time.current)
    profile = Profile.new(response: response)
    assert profile.valid?
  end

  test "should generate unique_token automatically" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!(status: "submitted", submitted_at: Time.current)
    profile = response.create_profile!
    assert_not_nil profile.unique_token
    assert_equal 36, profile.unique_token.length
  end

  test "should default viewed_count to 0" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!(status: "submitted", submitted_at: Time.current)
    profile = response.create_profile!
    assert_equal 0, profile.viewed_count
  end

  test "increment_view_count! increments counter" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!(status: "submitted", submitted_at: Time.current)
    profile = response.create_profile!

    profile.increment_view_count!
    assert_equal 1, profile.viewed_count
  end

  test "should require response to be submitted" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    draft_response = quest.responses.create!(status: "draft")
    profile = Profile.new(response: draft_response)

    assert_not profile.valid?
    assert_includes profile.errors[:response], "must be submitted before creating a profile"
  end

  test "should have unique response_id" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!(status: "submitted", submitted_at: Time.current)
    profile1 = response.create_profile!
    profile2 = Profile.new(response: response)

    assert_not profile2.valid?
    assert_includes profile2.errors[:response_id], "has already been taken"
  end
end
