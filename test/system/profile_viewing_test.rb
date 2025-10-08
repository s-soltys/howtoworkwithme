require "application_system_test_case"

class ProfileViewingTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Org")
    @questionnaire = @organization.questionnaires.create!(title: "Team Survey")

    # Create category and questions
    @category = @questionnaire.categories.create!(name: "About You", position: 1)

    @question1 = @category.questions.create!(
      question_type: "text",
      text: "What motivates you?",
      position: 1,
      required: true
    )

    @question2 = @category.questions.build(
      question_type: "single_choice",
      text: "Work style preference?",
      position: 2,
      required: true,
      question_options_attributes: [
        { text: "Independent", position: 1 },
        { text: "Collaborative", position: 2 }
      ]
    )
    @question2.save!

    # Create employee and response
    @employee = @organization.employees.create!(name: "Charlie Brown")
    @response = @questionnaire.responses.create!(
      employee: @employee,
      status: "submitted",
      submitted_at: Time.current
    )

    # Create answers
    @response.answers.create!(
      question: @question1,
      text_value: "Making a positive impact"
    )

    @response.answers.create!(
      question: @question2,
      selected_option_id: @question2.question_options.first.id
    )

    # Create profile
    @profile = @response.create_profile!
  end

  test "colleague opens profile link and sees employee information" do
    # Visit the profile
    visit profile_path(@profile.unique_token)

    # Verify employee name is displayed
    assert_selector "h1", text: "Charlie Brown's Profile"

    # Verify questionnaire title is displayed
    assert_text "Team Survey"

    # Verify category is displayed
    assert_text "About You"

    # Verify questions and answers are displayed
    assert_text "What motivates you?"
    assert_text "Making a positive impact"

    assert_text "Work style preference?"
    assert_text "Independent"

    # Verify view count is displayed
    assert_text "This profile has been viewed 1 time"
  end

  test "profile view count increments on each visit" do
    # First visit
    visit profile_path(@profile.unique_token)
    assert_text "This profile has been viewed 1 time"

    # Refresh/revisit
    visit profile_path(@profile.unique_token)
    assert_text "This profile has been viewed 2 times"

    # One more time
    visit profile_path(@profile.unique_token)
    assert_text "This profile has been viewed 3 times"
  end

  test "invalid profile link shows 404 error" do
    # Visit with invalid token
    visit profile_path("invalid-token-that-does-not-exist")

    # Should see 404 page with error message
    assert_text "page you were looking for"
  end

  test "profile displays all answer types correctly" do
    # Create a more complex questionnaire with all question types
    questionnaire2 = @organization.questionnaires.create!(title: "Complex Survey")
    category2 = questionnaire2.categories.create!(name: "Testing", position: 1)

    text_q = category2.questions.create!(
      question_type: "text",
      text: "Text question?",
      position: 1
    )

    single_q = category2.questions.build(
      question_type: "single_choice",
      text: "Single choice question?",
      position: 2,
      question_options_attributes: [
        { text: "Option A", position: 1 },
        { text: "Option B", position: 2 }
      ]
    )
    single_q.save!

    multi_q = category2.questions.build(
      question_type: "multiple_choice",
      text: "Multiple choice question?",
      position: 3,
      question_options_attributes: [
        { text: "First", position: 1 },
        { text: "Second", position: 2 },
        { text: "Third", position: 3 }
      ]
    )
    multi_q.save!

    yesno_q = category2.questions.create!(
      question_type: "yes_no",
      text: "Yes/No question?",
      position: 4
    )

    # Create response with all answer types
    employee2 = @organization.employees.create!(name: "Diana Prince")
    response2 = questionnaire2.responses.create!(
      employee: employee2,
      status: "submitted",
      submitted_at: Time.current
    )

    response2.answers.create!(question: text_q, text_value: "Text answer here")
    response2.answers.create!(question: single_q, selected_option_id: single_q.question_options.first.id)
    response2.answers.create!(
      question: multi_q,
      selected_option_ids: [multi_q.question_options.first.id, multi_q.question_options.last.id]
    )
    response2.answers.create!(question: yesno_q, boolean_value: true)

    profile2 = response2.create_profile!

    # Visit profile
    visit profile_path(profile2.unique_token)

    # Verify all answer types display correctly
    assert_text "Text answer here"
    assert_text "Option A"
    assert_text "First"
    assert_text "Third"
    assert_text "Yes"
  end

  test "profile shows unanswered questions appropriately" do
    # Create response with unanswered question
    @question3 = @category.questions.create!(
      question_type: "text",
      text: "Optional question?",
      position: 3,
      required: false
    )

    # Reload response to pick up new question
    @response.reload

    # Visit profile
    visit profile_path(@profile.unique_token)

    # Verify unanswered question shows "Not answered"
    assert_text "Optional question?"
    assert_text "Not answered"
  end
end
