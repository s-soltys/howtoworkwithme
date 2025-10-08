require "test_helper"

class ResponsesControllerTest < ActionDispatch::IntegrationTest
  # Most controller functionality is tested through system tests
  # These are minimal smoke tests for specific answer types

  test "should save slider answer via update" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "slider",
      text: "Rate this",
      position: 1,
      settings: { min_value: 1, max_value: 10 }
    )
    response = quest.responses.create!

    patch response_path(response.unique_token),
      params: {
        response: {
          answers_attributes: {
            "0" => {
              question_id: question.id,
              numeric_value: 7
            }
          }
        }
      },
      as: :turbo_stream

    assert_response :success
    answer = response.answers.find_by(question: question)
    assert_equal 7, answer.numeric_value
  end
end
