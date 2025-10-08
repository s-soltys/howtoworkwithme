require "test_helper"

class QuestionOptionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
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
    option = question.question_options.first
    assert option.valid?
    assert_equal "Option 1", option.text
  end

  test "should require text" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(question_type: "single_choice", text: "Choose", position: 1)
    option = question.question_options.build(position: 1)
    assert_not option.valid?
  end
end
