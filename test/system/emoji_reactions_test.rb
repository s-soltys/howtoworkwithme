require "application_system_test_case"

class EmojiReactionsTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Quick Reactions",
      description: "Express your feelings with emojis"
    )

    @category = @questionnaire.categories.create!(name: "Feelings", position: 1)

    # Create emoji reaction question
    @emoji_question = @category.questions.create!(
      question_type: "emoji_reaction",
      text: "How do you feel about daily stand-up meetings?",
      position: 1,
      required: true,
      settings: {
        "emoji_options" => [
          {
            "emoji" => "😍",
            "label" => "Love them",
            "value" => 5
          },
          {
            "emoji" => "😊",
            "label" => "Like them",
            "value" => 4
          },
          {
            "emoji" => "😐",
            "label" => "Neutral",
            "value" => 3
          },
          {
            "emoji" => "😕",
            "label" => "Dislike them",
            "value" => 2
          },
          {
            "emoji" => "😤",
            "label" => "Hate them",
            "value" => 1
          }
        ]
      }
    )
  end

  test "employee sees emoji reaction question with all emoji options" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify emoji question is displayed
    assert_text "How do you feel about daily stand-up meetings?"
    assert_text "Select an emoji that best represents your response"

    # Verify all emoji options are displayed
    assert_text "😍"
    assert_text "😊"
    assert_text "😐"
    assert_text "😕"
    assert_text "😤"

    # Verify emoji reaction controller is initialized
    assert_selector "[data-controller='emoji-reaction']"

    # Verify all emoji buttons are present
    assert_selector "[data-emoji-reaction-target='option']", count: 5
  end

  test "employee can select an emoji and answer is saved" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Find and click the "Love them" emoji
    love_emoji_button = find("[data-emoji-reaction-target='option'][data-emoji='😍']")
    love_emoji_button.click

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Verify the selected emoji is highlighted
    assert love_emoji_button[:class].include?("btn-primary")
    assert love_emoji_button[:class].include?("scale-125")

    # Verify label is displayed
    assert_text "Love them"

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved with correct emoji data
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @emoji_question)

    assert answer.jsonb_value.present?
    assert_equal "😍", answer.jsonb_value["emoji"]
    assert_equal "Love them", answer.jsonb_value["label"]
    assert_equal 5, answer.jsonb_value["value"]
  end

  test "selecting different emoji updates the selection" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Select first emoji
    first_emoji = find("[data-emoji-reaction-target='option'][data-emoji='😍']")
    first_emoji.click

    # Wait for selection
    sleep 0.5

    # Verify first emoji is selected
    assert first_emoji[:class].include?("btn-primary")

    # Select different emoji
    second_emoji = find("[data-emoji-reaction-target='option'][data-emoji='😐']")
    second_emoji.click

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Verify first emoji is deselected
    assert_not first_emoji[:class].include?("btn-primary")

    # Verify second emoji is selected
    assert second_emoji[:class].include?("btn-primary")
    assert_text "Neutral"
  end

  test "emoji selection persists across page navigation" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Select an emoji
    neutral_emoji = find("[data-emoji-reaction-target='option'][data-emoji='😐']")
    neutral_emoji.click

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Reload the page
    visit current_path

    # Verify the selection persisted
    reloaded_emoji = find("[data-emoji-reaction-target='option'][data-emoji='😐']")
    assert reloaded_emoji[:class].include?("btn-primary")
    assert reloaded_emoji[:class].include?("scale-125")

    # Verify label is still displayed
    assert_text "Neutral"
  end

  test "emoji buttons show tooltip with label" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify each emoji button has a title attribute (tooltip)
    love_button = find("[data-emoji-reaction-target='option'][data-emoji='😍']")
    assert_equal "Love them", love_button["title"]

    hate_button = find("[data-emoji-reaction-target='option'][data-emoji='😤']")
    assert_equal "Hate them", hate_button["title"]
  end

  test "emoji reaction shows instruction text" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify instructions
    assert_text "Select an emoji that best represents your response"
    assert_text "Tap an emoji to react"
  end
end
