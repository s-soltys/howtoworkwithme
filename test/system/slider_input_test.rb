require "application_system_test_case"

class SliderInputTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Personality Assessment",
      description: "Understand your personality traits"
    )

    @category = @questionnaire.categories.create!(name: "Personality", position: 1)

    # Create slider question with labeled endpoints
    @slider_question = @category.questions.create!(
      question_type: "slider",
      text: "How introverted or extroverted are you?",
      position: 1,
      required: true,
      settings: {
        "min_value" => 1,
        "max_value" => 10,
        "step" => 1,
        "labels" => {
          "1" => "Very Introverted",
          "5" => "Balanced",
          "10" => "Very Extroverted"
        },
        "default_value" => 5
      }
    )
  end

  test "employee can answer slider question and value is saved" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify slider is displayed with correct settings
    assert_selector "input[type='range'][min='1'][max='10']"
    assert_text "How introverted or extroverted are you?"

    # Verify endpoint labels are displayed
    assert_text "Very Introverted"
    assert_text "Very Extroverted"

    # Verify default value is displayed
    within "[data-slider-target='valueDisplay']" do
      assert_text "5"
    end

    # Change slider value using JavaScript (Capybara doesn't support range inputs natively)
    slider = find("input[type='range']", match: :first)
    page.execute_script("arguments[0].value = 7", slider)
    page.execute_script("arguments[0].dispatchEvent(new Event('input', { bubbles: true }))", slider)
    page.execute_script("arguments[0].dispatchEvent(new Event('change', { bubbles: true }))", slider)

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Verify value display updated
    within "[data-slider-target='valueDisplay']" do
      assert_text "7"
    end

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved correctly
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @slider_question)
    assert_equal 7, answer.numeric_value
  end

  test "slider shows semantic label when available" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify default semantic label is shown
    within "[data-slider-target='label']" do
      assert_text "Balanced"
    end

    # Change to value with semantic label
    slider = find("input[type='range']", match: :first)
    page.execute_script("arguments[0].value = 10", slider)
    page.execute_script("arguments[0].dispatchEvent(new Event('input', { bubbles: true }))", slider)

    # Verify semantic label updated
    within "[data-slider-target='label']" do
      assert_text "Very Extroverted"
    end
  end

  test "slider value persists across page navigation" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Set slider value
    slider = find("input[type='range']", match: :first)
    page.execute_script("arguments[0].value = 8", slider)
    page.execute_script("arguments[0].dispatchEvent(new Event('change', { bubbles: true }))", slider)

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Reload the page
    visit current_path

    # Verify value persisted
    within "[data-slider-target='valueDisplay']" do
      assert_text "8"
    end

    slider_value = find("input[type='range']", match: :first).value
    assert_equal "8", slider_value
  end
end
