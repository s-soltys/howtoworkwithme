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
    question = category.questions.create!(question_type: "single_choice", text: "Choose", position: 1)

    # Add only 1 option
    question.question_options.create!(text: "Option 1", position: 1)

    # Validation should fail when we try to update with insufficient options
    question.text = "Updated text"
    assert_not question.valid?
    assert_includes question.errors[:base], "Choice questions must have at least 2 options"
  end

  # Slider question tests (T015)
  test "slider question should be valid with proper settings" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "slider",
      text: "How introverted/extroverted are you?",
      position: 1,
      settings: {
        min_value: 1,
        max_value: 10,
        labels: { "1" => "Introvert", "10" => "Extrovert" }
      }
    )
    assert question.valid?
  end

  test "slider question requires min_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "slider",
      text: "Rate this",
      position: 1,
      settings: { max_value: 10 }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "must include min_value"
  end

  test "slider question requires max_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "slider",
      text: "Rate this",
      position: 1,
      settings: { min_value: 1 }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "must include max_value"
  end

  test "slider question min_value must be less than max_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "slider",
      text: "Rate this",
      position: 1,
      settings: { min_value: 10, max_value: 5 }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "min_value must be less than max_value"
  end

  # Swipe yes/no question tests (T025)
  test "swipe_yes_no question should be valid with proper settings" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "swipe_yes_no",
      text: "Do you enjoy working remotely?",
      position: 1,
      settings: {
        swipe_threshold: 0.3,
        positive_label: "Yes",
        negative_label: "No",
        animation_duration: 300
      }
    )
    assert question.valid?
  end

  test "swipe_yes_no question is valid with minimal settings" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "swipe_yes_no",
      text: "Do you like meetings?",
      position: 1,
      settings: {}
    )
    # Settings are optional for swipe_yes_no - defaults will be used in UI
    assert question.valid?
  end

  # Card sort question tests (T036)
  test "card_sort question should be valid with proper settings" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "card_sort",
      text: "Rank these work values by importance",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" },
          { id: "card-4", text: "Team culture" }
        ],
        allow_partial_ranking: true
      }
    )
    assert question.valid?
  end

  test "card_sort question requires cards array" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "card_sort",
      text: "Rank these",
      position: 1,
      settings: { allow_partial_ranking: true }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "must include cards array"
  end

  test "card_sort question requires minimum 3 cards" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "card_sort",
      text: "Rank these",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Option 1" },
          { id: "card-2", text: "Option 2" }
        ]
      }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "must have between 3 and 15 cards"
  end

  test "card_sort question requires unique card IDs" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "card_sort",
      text: "Rank these",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Option 1" },
          { id: "card-1", text: "Option 2" },
          { id: "card-3", text: "Option 3" }
        ]
      }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "card IDs must be unique"
  end

  test "card_sort question requires id and text for each card" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.build(
      question_type: "card_sort",
      text: "Rank these",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Option 1" },
          { id: "card-2" },  # Missing text
          { text: "Option 3" }  # Missing id
        ]
      }
    )
    assert_not question.valid?
    assert_includes question.errors[:settings], "each card must have an id and text"
  end
end
