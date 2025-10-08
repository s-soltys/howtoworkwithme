require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "should be valid with valid text question" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(question_type: "text", text: "Name?", position: 1)
    assert question.valid?
  end

  test "should require text" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(question_type: "text", position: 1)
    assert_not question.valid?
  end

  test "should have question_type enum" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(text: "Test?", position: 1, question_type: "text")
    assert question.text?

    question.question_type = "single_choice"
    assert question.single_choice?
  end

  test "choice questions require at least 2 options" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(question_type: "single_choice", text: "Choose", position: 1)
    assert_not question.valid?
  end
end
