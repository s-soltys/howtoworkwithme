require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "text question should require text_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(question_type: "text", text: "Name?", position: 1)
    response = quest.responses.create!
    answer = response.answers.build(question: question, text_value: nil)
    assert_not answer.valid?
  end

  test "text_value should be max 1000 characters" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(question_type: "text", text: "Name?", position: 1)
    response = quest.responses.create!
    answer = response.answers.build(question: question, text_value: "a" * 1001)
    assert_not answer.valid?
  end

  test "single_choice question should require selected_option_id" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "single_choice",
      text: "Choose",
      position: 1,
      question_options_attributes: [
        { text: "Option 1", position: 1 },
        { text: "Option 2", position: 2 }
      ]
    )
    question.save!
    response = quest.responses.create!
    answer = response.answers.build(question: question)
    assert_not answer.valid?
  end

  test "yes_no question should require boolean_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(question_type: "yes_no", text: "Agree?", position: 1)
    response = quest.responses.create!
    answer = response.answers.build(question: question)
    assert_not answer.valid?
  end
end
