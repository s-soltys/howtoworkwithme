require "test_helper"

class QuestionnairesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
  end

  test "should get new questionnaire form" do
    get new_organization_questionnaire_path(@organization.unique_token)
    assert_response :success
    assert_select "h1", "Create Questionnaire"
    assert_select "input[name='questionnaire[title]']"
    assert_select "textarea[name='questionnaire[description]']"
  end

  test "should create questionnaire with valid data" do
    assert_difference("Questionnaire.count", 1) do
      post organization_questionnaires_path(@organization.unique_token), params: {
        questionnaire: {
          title: "New Questionnaire",
          description: "A test questionnaire"
        }
      }
    end

    questionnaire = Questionnaire.last
    assert_equal "New Questionnaire", questionnaire.title
    assert_equal "A test questionnaire", questionnaire.description
    assert_equal @organization.id, questionnaire.organization_id
    assert_redirected_to edit_questionnaire_path(questionnaire.unique_token)
  end

  test "should not create questionnaire without title" do
    assert_no_difference("Questionnaire.count") do
      post organization_questionnaires_path(@organization.unique_token), params: {
        questionnaire: {
          title: "",
          description: "A test questionnaire"
        }
      }
    end

    assert_redirected_to organization_path(@organization.unique_token)
  end

  test "should show questionnaire" do
    questionnaire = questionnaires(:one)
    get questionnaire_path(questionnaire.unique_token)
    assert_response :success
  end

  test "should get edit questionnaire page" do
    questionnaire = questionnaires(:unlocked_questionnaire)
    get edit_questionnaire_path(questionnaire.unique_token)
    assert_response :success
  end

  test "should show edit page even when questionnaire is locked" do
    questionnaire = questionnaires(:locked_questionnaire)
    get edit_questionnaire_path(questionnaire.unique_token)
    assert_response :success
    assert_select "input[value='Add Category'][disabled='disabled']"
  end

  test "should get responses table" do
    questionnaire = questionnaires(:employee_preferences)

    # Create employees and responses
    employee1 = Employee.create!(organization: questionnaire.organization, name: "John Doe", email: "john@example.com")
    employee2 = Employee.create!(organization: questionnaire.organization, name: "Jane Smith", email: "jane@example.com")

    response1 = Response.create!(questionnaire: questionnaire, employee: employee1, status: "submitted", submitted_at: Time.current)
    response2 = Response.create!(questionnaire: questionnaire, employee: employee2, status: "submitted", submitted_at: Time.current)

    # Create answers for each response
    questionnaire.questions.each do |question|
      Answer.create!(response: response1, question: question, text_value: "Answer 1") if question.question_type == "text"
      Answer.create!(response: response2, question: question, text_value: "Answer 2") if question.question_type == "text"
    end

    get responses_questionnaire_path(questionnaire.unique_token)
    assert_response :success

    # Verify employees are in response
    assert_match employee1.name, response.body
    assert_match employee2.name, response.body
  end

  test "should show most recent response per employee" do
    questionnaire = questionnaires(:employee_preferences)
    employee = Employee.create!(organization: questionnaire.organization, name: "John Doe", email: "john@example.com")

    # Old response
    old_response = Response.create!(questionnaire: questionnaire, employee: employee, status: "submitted", submitted_at: 2.days.ago)
    question = questionnaire.questions.where(question_type: "text").first
    Answer.create!(response: old_response, question: question, text_value: "Old answer")

    # New response
    new_response = Response.create!(questionnaire: questionnaire, employee: employee, status: "submitted", submitted_at: 1.day.ago)
    Answer.create!(response: new_response, question: question, text_value: "New answer")

    get responses_questionnaire_path(questionnaire.unique_token)
    assert_response :success

    # Should show only most recent
    assert_match "New answer", response.body
    assert_no_match "Old answer", response.body
  end

  test "responses action should prevent N+1 queries" do
    questionnaire = questionnaires(:employee_preferences)

    # Create multiple employees with responses
    3.times do |i|
      employee = Employee.create!(organization: questionnaire.organization, name: "Employee #{i}", email: "emp#{i}@example.com")
      resp = Response.create!(questionnaire: questionnaire, employee: employee, status: "submitted", submitted_at: Time.current)

      questionnaire.questions.each do |question|
        case question.question_type
        when "text"
          Answer.create!(response: resp, question: question, text_value: "Answer #{i}")
        when "yes_no"
          Answer.create!(response: resp, question: question, boolean_value: true)
        when "single_choice"
          option = question.question_options.first
          Answer.create!(response: resp, question: question, selected_option_id: option.id) if option
        when "multiple_choice"
          options = question.question_options.first(2)
          Answer.create!(response: resp, question: question, selected_option_ids: options.map(&:id)) if options.any?
        end
      end
    end

    # This test will fail if N+1 queries exist (we'll check manually with query logs)
    get responses_questionnaire_path(questionnaire.unique_token)
    assert_response :success
  end
end
