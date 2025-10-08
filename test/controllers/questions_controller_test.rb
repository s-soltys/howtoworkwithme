require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:one)
    @questionnaire = @category.questionnaire
    @question = questions(:one)
  end

  test "should create question with Turbo Stream" do
    assert_difference("Question.count", 1) do
      post category_questions_path(@category),
        params: {
          question: {
            text: "What is your preferred working time?",
            question_type: "text",
            position: 1,
            required: true
          }
        },
        as: :turbo_stream
    end

    assert_response :success
  end

  test "should create question with options for choice types" do
    assert_difference("Question.count", 1) do
      assert_difference("QuestionOption.count", 3) do
        post category_questions_path(@category),
          params: {
            question: {
              text: "Communication preference?",
              question_type: "single_choice",
              required: true,
              question_options_attributes: [
                { text: "Email", position: 1 },
                { text: "Slack", position: 2 },
                { text: "Phone", position: 3 }
              ]
            }
          },
          as: :turbo_stream
      end
    end

    assert_response :success
  end

  test "should not create question for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    assert_no_difference("Question.count") do
      post category_questions_path(@category),
        params: { question: { text: "New Question", question_type: "text" } },
        as: :turbo_stream
    end

    assert_response :forbidden
  end

  test "should update question with Turbo Stream" do
    patch question_path(@question),
      params: { question: { text: "Updated question text?" } },
      as: :turbo_stream

    assert_response :success
    @question.reload
    assert_equal "Updated question text?", @question.text
  end

  test "should not update question for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    patch question_path(@question),
      params: { question: { text: "Updated text" } },
      as: :turbo_stream

    assert_response :forbidden
  end

  test "should destroy question with Turbo Stream" do
    assert_difference("Question.count", -1) do
      delete question_path(@question), as: :turbo_stream
    end

    assert_response :success
  end

  test "should not destroy question for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    assert_no_difference("Question.count") do
      delete question_path(@question), as: :turbo_stream
    end

    assert_response :forbidden
  end
end
