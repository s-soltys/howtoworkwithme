require "application_system_test_case"

class EmployerViewsResponsesTest < ApplicationSystemTestCase
  test "employer views employee responses in table format" do
    # Setup: Create organization, questionnaire with categories and questions
    org = organizations(:acme)
    questionnaire = questionnaires(:employee_preferences)

    # Verify we have 3 categories with questions
    assert_equal 3, questionnaire.categories.count
    assert_equal 5, questionnaire.questions.count

    # Setup: Create 3 employees with submitted responses
    employees = []
    3.times do |i|
      employee = Employee.create!(
        organization: org,
        name: "Employee #{i + 1}",
        email: "employee#{i + 1}@example.com"
      )

      response = Response.create!(
        questionnaire: questionnaire,
        employee: employee,
        status: "submitted",
        submitted_at: Time.current
      )

      # Create answers for all questions
      questionnaire.questions.each do |question|
        case question.question_type
        when "text"
          Answer.create!(
            response: response,
            question: question,
            text_value: "Answer from Employee #{i + 1}"
          )
        when "single_choice"
          option = question.question_options.first
          Answer.create!(
            response: response,
            question: question,
            selected_option_id: option.id
          )
        when "multiple_choice"
          options = question.question_options.first(2)
          Answer.create!(
            response: response,
            question: question,
            selected_option_ids: options.map(&:id)
          )
        when "yes_no"
          Answer.create!(
            response: response,
            question: question,
            boolean_value: true
          )
        end
      end

      employees << employee
    end

    # Navigate to responses table
    visit responses_questionnaire_path(questionnaire.unique_token)

    # Verify table has 3 rows (one per employee)
    assert_selector "table tbody tr", count: 3

    # Verify all employee names are shown
    employees.each do |employee|
      assert_text employee.name
    end

    # Verify questions are displayed as columns (grouped by category)
    questionnaire.categories.each do |category|
      assert_text category.name
      category.questions.each do |question|
        assert_text question.text
      end
    end

    # Verify answers are displayed in cells
    assert_text "Answer from Employee 1"
    assert_text "Answer from Employee 2"
    assert_text "Answer from Employee 3"
  end

  test "employer sees most recent submission when employee submits multiple times" do
    org = organizations(:acme)
    questionnaire = questionnaires(:employee_preferences)
    employee = Employee.create!(
      organization: org,
      name: "John Doe",
      email: "john@example.com"
    )

    # First submission
    old_response = Response.create!(
      questionnaire: questionnaire,
      employee: employee,
      status: "submitted",
      submitted_at: 2.days.ago
    )

    question = questionnaire.questions.where(question_type: "text").first
    Answer.create!(
      response: old_response,
      question: question,
      text_value: "Old answer"
    )

    # Second submission (more recent)
    new_response = Response.create!(
      questionnaire: questionnaire,
      employee: employee,
      status: "submitted",
      submitted_at: 1.day.ago
    )

    Answer.create!(
      response: new_response,
      question: question,
      text_value: "New answer"
    )

    # Navigate to responses table
    visit responses_questionnaire_path(questionnaire.unique_token)

    # Verify only most recent submission is shown
    assert_text "New answer"
    assert_no_text "Old answer"
  end

  test "employer dashboard shows correct answers for different question types" do
    org = organizations(:acme)
    questionnaire = questionnaires(:employee_preferences)
    employee = Employee.create!(
      organization: org,
      name: "Test Employee",
      email: "test@example.com"
    )

    response = Response.create!(
      questionnaire: questionnaire,
      employee: employee,
      status: "submitted",
      submitted_at: Time.current
    )

    # Text question
    text_question = questionnaire.questions.find_by(question_type: "text")
    Answer.create!(
      response: response,
      question: text_question,
      text_value: "I prefer async communication"
    )

    # Single choice question
    single_choice_question = questionnaire.questions.find_by(question_type: "single_choice")
    option = single_choice_question.question_options.first
    Answer.create!(
      response: response,
      question: single_choice_question,
      selected_option_id: option.id
    )

    # Multiple choice question
    multiple_choice_question = questionnaire.questions.find_by(question_type: "multiple_choice")
    options = multiple_choice_question.question_options.first(2)
    Answer.create!(
      response: response,
      question: multiple_choice_question,
      selected_option_ids: options.map(&:id)
    )

    # Yes/No question
    yes_no_question = questionnaire.questions.find_by(question_type: "yes_no")
    Answer.create!(
      response: response,
      question: yes_no_question,
      boolean_value: true
    )

    # Navigate to responses table
    visit responses_questionnaire_path(questionnaire.unique_token)

    # Verify all answer types are displayed correctly
    assert_text "I prefer async communication"  # Text answer
    assert_text option.text  # Single choice answer
    options.each { |opt| assert_text opt.text }  # Multiple choice answers
    assert_text "Yes"  # Yes/No answer
  end
end
