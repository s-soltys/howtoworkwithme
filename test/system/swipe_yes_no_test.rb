require "application_system_test_case"

class SwipeYesNoTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Quick Preferences",
      description: "Swipe-based preference questions"
    )

    @category = @questionnaire.categories.create!(name: "Preferences", position: 1)

    # Create swipe yes/no question
    @swipe_question = @category.questions.create!(
      question_type: "swipe_yes_no",
      text: "Do you enjoy working in teams?",
      position: 1,
      required: true,
      settings: {
        "swipe_threshold" => 0.3,
        "positive_label" => "Love it",
        "negative_label" => "Prefer solo",
        "animation_duration" => 300
      }
    )
  end

  test "employee can answer swipe question using keyboard (arrow keys)" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify swipe question is displayed
    assert_text "Do you enjoy working in teams?"
    assert_text "Swipe right for Love it, left for Prefer solo"

    # Focus on swipe container
    swipe_container = find("[data-controller='swipe']")
    swipe_container.send_keys(:arrow_right)

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved as true (yes)
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @swipe_question)
    assert_equal true, answer.boolean_value
  end

  test "employee can answer swipe question with left arrow (no)" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Focus on swipe container and press left arrow
    swipe_container = find("[data-controller='swipe']")
    swipe_container.send_keys(:arrow_left)

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Verify answer was saved as false (no)
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @swipe_question)
    assert_equal false, answer.boolean_value
  end

  test "swipe question displays custom labels" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify custom labels are displayed
    assert_text "Love it"
    assert_text "Prefer solo"
  end

  test "swipe answer persists across page navigation" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Answer with right arrow (yes)
    swipe_container = find("[data-controller='swipe']")
    swipe_container.send_keys(:arrow_right)

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Reload the page
    visit current_path

    # Verify answer persisted
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @swipe_question)
    assert_equal true, answer.boolean_value
  end
end
