require "test_helper"

class ResponseTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    employee = org.employees.create!(name: "Alice")
    response = Response.new(questionnaire: quest, employee: employee)
    assert response.valid?
  end

  test "should generate unique_token automatically" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!
    assert_not_nil response.unique_token
    assert_equal 36, response.unique_token.length
  end

  test "should default status to draft" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!
    assert_equal "draft", response.status
    assert response.draft?
  end

  test "submit! changes status to submitted and sets timestamp" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    response = quest.responses.create!

    response.submit!
    assert_equal "submitted", response.status
    assert response.submitted?
    assert_not_nil response.submitted_at
  end

  test "should have draft and submitted scopes" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    draft = quest.responses.create!(status: "draft")
    submitted = quest.responses.create!(status: "submitted", submitted_at: Time.current)

    assert_includes Response.draft, draft
    assert_not_includes Response.draft, submitted
    assert_includes Response.submitted, submitted
    assert_not_includes Response.submitted, draft
  end

  test "most_recent_first scope orders by submitted_at desc" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    old = quest.responses.create!(status: "submitted", submitted_at: 2.days.ago)
    new = quest.responses.create!(status: "submitted", submitted_at: 1.day.ago)

    assert_equal [ new, old ], Response.most_recent_first.to_a
  end
end
