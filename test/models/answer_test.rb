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

  # Slider answer tests (T016)
  test "slider question should require numeric_value" do
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
    answer = response.answers.build(question: question)
    assert_not answer.valid?
    assert_includes answer.errors[:numeric_value], "must be present for required slider questions"
  end

  test "slider answer value must be within min/max range" do
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

    # Test value below minimum
    answer = response.answers.build(question: question, numeric_value: 0)
    assert_not answer.valid?
    assert_includes answer.errors[:numeric_value], "must be at least 1"

    # Test value above maximum
    answer = response.answers.build(question: question, numeric_value: 15)
    assert_not answer.valid?
    assert_includes answer.errors[:numeric_value], "must be at most 10"
  end

  test "slider answer should be valid with value in range" do
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
    answer = response.answers.build(question: question, numeric_value: 7)
    assert answer.valid?
  end

  # Swipe yes/no answer tests (T026)
  test "swipe_yes_no question should require boolean_value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "swipe_yes_no",
      text: "Do you like remote work?",
      position: 1,
      settings: {}
    )
    response = quest.responses.create!
    answer = response.answers.build(question: question)
    assert_not answer.valid?
    assert_includes answer.errors[:boolean_value], "must be present for required swipe yes/no questions"
  end

  test "swipe_yes_no answer should be valid with true value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "swipe_yes_no",
      text: "Do you like remote work?",
      position: 1,
      settings: {}
    )
    response = quest.responses.create!
    answer = response.answers.build(question: question, boolean_value: true)
    assert answer.valid?
  end

  test "swipe_yes_no answer should be valid with false value" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "swipe_yes_no",
      text: "Do you like remote work?",
      position: 1,
      settings: {}
    )
    response = quest.responses.create!
    answer = response.answers.build(question: question, boolean_value: false)
    assert answer.valid?
  end

  # Card sort answer tests (T037)
  test "card_sort question should require jsonb_value with ranked cards" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" }
        ]
      }
    )
    response = quest.responses.create!
    answer = response.answers.build(question: question)
    assert_not answer.valid?
    assert_includes answer.errors[:jsonb_value], "must include at least one ranked card for required card sort questions"
  end

  test "card_sort answer should be valid with properly ranked cards" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" }
        ]
      }
    )
    response = quest.responses.create!
    answer = response.answers.build(
      question: question,
      jsonb_value: {
        ranked: [
          { id: "card-2", rank: 1 },
          { id: "card-1", rank: 2 },
          { id: "card-3", rank: 3 }
        ],
        unranked: []
      }
    )
    assert answer.valid?
  end

  test "card_sort answer should reject invalid card IDs" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" }
        ]
      }
    )
    response = quest.responses.create!
    answer = response.answers.build(
      question: question,
      jsonb_value: {
        ranked: [
          { id: "card-99", rank: 1 }  # Invalid ID
        ],
        unranked: []
      }
    )
    assert_not answer.valid?
    assert_includes answer.errors[:jsonb_value], "contains invalid card IDs: card-99"
  end

  test "card_sort answer should reject duplicate card IDs" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" }
        ]
      }
    )
    response = quest.responses.create!
    answer = response.answers.build(
      question: question,
      jsonb_value: {
        ranked: [
          { id: "card-1", rank: 1 },
          { id: "card-1", rank: 2 }  # Duplicate
        ],
        unranked: []
      }
    )
    assert_not answer.valid?
    assert_includes answer.errors[:jsonb_value], "contains duplicate card IDs"
  end

  test "card_sort answer should require sequential ranks" do
    org = Organization.create!(name: "Acme")
    quest = org.questionnaires.create!(title: "Survey")
    category = quest.categories.create!(name: "Personal", position: 1)
    question = category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values",
      position: 1,
      settings: {
        cards: [
          { id: "card-1", text: "Work-life balance" },
          { id: "card-2", text: "Career growth" },
          { id: "card-3", text: "Compensation" }
        ]
      }
    )
    response = quest.responses.create!
    answer = response.answers.build(
      question: question,
      jsonb_value: {
        ranked: [
          { id: "card-1", rank: 1 },
          { id: "card-2", rank: 3 }  # Gap in sequence
        ],
        unranked: []
      }
    )
    assert_not answer.valid?
    assert_includes answer.errors[:jsonb_value], "ranks must be sequential starting from 1"
  end
end
