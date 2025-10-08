require "application_system_test_case"

class EmployeeCompletesQuestionnaireTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Acme Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "How to Work With Me",
      description: "Help us understand your working style"
    )

    # Create categories
    @personal_category = @questionnaire.categories.create!(name: "Personal Preferences", position: 1)
    @communication_category = @questionnaire.categories.create!(name: "Communication", position: 2)

    # Create questions
    @text_question = @personal_category.questions.create!(
      question_type: "text",
      text: "What are your peak productivity hours?",
      position: 1,
      required: true
    )

    @single_choice_question = @personal_category.questions.build(
      question_type: "single_choice",
      text: "Preferred work environment?",
      position: 2,
      required: true,
      question_options_attributes: [
        { text: "Remote", position: 1 },
        { text: "Office", position: 2 },
        { text: "Hybrid", position: 3 }
      ]
    )
    @single_choice_question.save!

    @yes_no_question = @communication_category.questions.create!(
      question_type: "yes_no",
      text: "Do you prefer written communication?",
      position: 1,
      required: true
    )
  end

  test "employee opens questionnaire, answers questions, submits, and receives profile link" do
    # Visit the questionnaire landing page
    visit questionnaire_path(@questionnaire.unique_token)

    # Verify questionnaire title and description are displayed
    assert_selector "h1", text: @questionnaire.title
    assert_text @questionnaire.description

    # Enter employee name
    fill_in "employee_name", with: "Alice Johnson"

    # Click Start Questionnaire button
    click_button "Start Questionnaire"

    # Should be redirected to the questionnaire form
    assert_selector "h1", text: @questionnaire.title
    assert_text "Employee: Alice Johnson"

    # Verify all categories are displayed
    assert_text "Personal Preferences"
    assert_text "Communication"

    # Answer text question
    fill_in "What are your peak productivity hours?", with: "9 AM - 12 PM, 2 PM - 5 PM"

    # Answer single choice question
    choose "Remote"

    # Answer yes/no question
    choose "Yes"

    # Wait for autosave to complete
    assert_text "Saved", wait: 5

    # Submit the questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Should be redirected to profile page
    assert_text "Alice Johnson's Profile"
    assert_text "How to Work With Me"

    # Verify answers are displayed
    assert_text "What are your peak productivity hours?"
    assert_text "9 AM - 12 PM, 2 PM - 5 PM"

    assert_text "Preferred work environment?"
    assert_text "Remote"

    assert_text "Do you prefer written communication?"
    assert_text "Yes"

    # Verify profile view count
    assert_text "This profile has been viewed 1 time"
  end

  test "employee sees validation error when submitting without required answers" do
    # Visit and start questionnaire
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Bob Smith"
    click_button "Start Questionnaire"

    # Try to submit without answering required questions
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Should see error message
    assert_text "Please answer all required questions"
  end

  test "employee cannot start questionnaire without name" do
    visit questionnaire_path(@questionnaire.unique_token)

    # Try to start without entering name (browser validation should prevent this)
    # This tests the required attribute on the name field
    assert_selector "input[name='employee_name'][required]"
  end
end
