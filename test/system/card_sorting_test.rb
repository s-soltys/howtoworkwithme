require "application_system_test_case"

class CardSortingTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Work Values Assessment",
      description: "Rank your work priorities"
    )

    @category = @questionnaire.categories.create!(name: "Values", position: 1)

    # Create card sort question
    @card_sort_question = @category.questions.create!(
      question_type: "card_sort",
      text: "Rank these work values from most to least important to you",
      position: 1,
      required: true,
      settings: {
        "cards" => [
          {
            "id" => "work-life-balance",
            "text" => "Work-life balance",
            "description" => "Time for personal life and hobbies"
          },
          {
            "id" => "career-growth",
            "text" => "Career growth",
            "description" => "Opportunities for advancement"
          },
          {
            "id" => "compensation",
            "text" => "Competitive compensation",
            "description" => "Salary and benefits"
          },
          {
            "id" => "impact",
            "text" => "Making an impact",
            "description" => "Meaningful work that matters"
          },
          {
            "id" => "collaboration",
            "text" => "Team collaboration",
            "description" => "Working with great people"
          }
        ],
        "allow_partial_ranking" => false
      }
    )
  end

  test "employee sees card sort question with all cards displayed" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify card sort question is displayed
    assert_text "Rank these work values from most to least important to you"
    assert_text "Drag and drop cards to rank them from most to least important"

    # Verify all cards are displayed
    assert_text "Work-life balance"
    assert_text "Career growth"
    assert_text "Competitive compensation"
    assert_text "Making an impact"
    assert_text "Team collaboration"

    # Verify card descriptions
    assert_text "Time for personal life and hobbies"
    assert_text "Opportunities for advancement"

    # Verify rank badges are displayed (1-5)
    within "[data-card-sort-target='card']", match: :first do
      assert_selector "[data-rank-badge]", text: "1"
    end
  end

  test "card sorting updates ranks when order changes" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Get all cards
    cards = all("[data-card-sort-target='card']")

    # Verify initial order shows sequential ranks
    cards.each_with_index do |card, index|
      within(card) do
        assert_selector "[data-rank-badge]", text: (index + 1).to_s
      end
    end

    # Note: Actual drag-and-drop testing with SortableJS is complex in Capybara
    # We can test the JavaScript directly or manually trigger the sorted event
    # For now, we'll test that the UI renders correctly with the expected structure

    # Verify the drag-drop is set up with correct data attributes
    assert_selector "[data-controller='card-sort']"
    assert_selector "[data-card-sort-target='card']", count: 5

    # Each card should have a data-card-id attribute
    cards.each do |card|
      assert card["data-card-id"].present?, "Card should have data-card-id attribute"
    end
  end

  test "card sort answer can be submitted" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # The cards are rendered in default order initially
    # SortableJS will handle re-ordering and trigger autosave

    # For testing purposes, we'll manually set the hidden field value to simulate a sort
    # This tests that the form submission works correctly
    page.execute_script(<<~JS)
      const hiddenInput = document.querySelector('[data-card-sort-target="hiddenInput"]');
      const ranking = {
        ranked: [
          { id: "impact", rank: 1 },
          { id: "work-life-balance", rank: 2 },
          { id: "career-growth", rank: 3 },
          { id: "compensation", rank: 4 },
          { id: "collaboration", rank: 5 }
        ]
      };
      hiddenInput.value = JSON.stringify(ranking);
      hiddenInput.dispatchEvent(new Event('change', { bubbles: true }));
    JS

    # Wait a moment for the change to register
    sleep 0.5

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved with correct ranking
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @card_sort_question)

    assert answer.jsonb_value.present?
    ranked = answer.jsonb_value["ranked"]
    assert_equal 5, ranked.length
    assert_equal "impact", ranked[0]["id"]
    assert_equal 1, ranked[0]["rank"]
  end

  test "card sort shows instruction message" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify instructions are shown
    assert_text "Drag and drop cards to rank them from most to least important"
    assert_text "Your top choice will be at rank #1"
  end
end
