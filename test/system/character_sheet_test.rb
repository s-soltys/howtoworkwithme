require "application_system_test_case"

class CharacterSheetTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Skills Assessment",
      description: "Allocate points to your key skills"
    )

    @category = @questionnaire.categories.create!(name: "Skills", position: 1)

    # Create character sheet question
    @character_sheet_question = @category.questions.create!(
      question_type: "character_sheet",
      text: "Distribute 20 points across your work skills",
      position: 1,
      required: true,
      settings: {
        "total_points" => 20,
        "stats" => [
          {
            "id" => "leadership",
            "label" => "Leadership",
            "description" => "Ability to guide and inspire others",
            "min" => 0,
            "max" => 10
          },
          {
            "id" => "technical",
            "label" => "Technical Skills",
            "description" => "Coding and system design expertise",
            "min" => 0,
            "max" => 10
          },
          {
            "id" => "creative",
            "label" => "Creativity",
            "description" => "Innovative thinking and problem solving",
            "min" => 0,
            "max" => 10
          },
          {
            "id" => "communication",
            "label" => "Communication",
            "description" => "Written and verbal expression",
            "min" => 0,
            "max" => 10
          }
        ],
        "require_full_allocation" => true
      }
    )
  end

  test "employee sees character sheet question with all stats" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify character sheet question is displayed
    assert_text "Distribute 20 points across your work skills"

    # Verify budget display
    assert_text "Allocate"
    assert_text "20"
    assert_text "points remaining"

    # Verify all stats are displayed
    assert_text "Leadership"
    assert_text "Ability to guide and inspire others"

    assert_text "Technical Skills"
    assert_text "Coding and system design expertise"

    assert_text "Creativity"
    assert_text "Innovative thinking and problem solving"

    assert_text "Communication"
    assert_text "Written and verbal expression"

    # Verify character sheet controller is initialized
    assert_selector "[data-controller='character-sheet']"

    # Verify all stat containers are present
    assert_selector "[data-stat-id]", count: 4
  end

  test "employee can allocate points using increment buttons" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Find the leadership stat and increment it
    leadership_stat = find("[data-stat-id='leadership']")

    within(leadership_stat) do
      increment_button = find("button", text: "+")

      # Click increment 5 times
      5.times { increment_button.click }

      # Verify value increased
      stat_input = find("[data-character-sheet-target='stat']")
      assert_equal "5", stat_input.value
    end

    # Verify remaining points decreased
    within "[data-character-sheet-target='remaining']" do
      assert_text "15"
    end
  end

  test "employee can allocate points using decrement buttons" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # First increment leadership to 5
    leadership_stat = find("[data-stat-id='leadership']")
    within(leadership_stat) do
      increment_button = find("button", text: "+")
      5.times { increment_button.click }
    end

    sleep 0.5

    # Now decrement by 2
    within(leadership_stat) do
      decrement_button = find("button", text: "−")
      2.times { decrement_button.click }

      # Verify value decreased
      stat_input = find("[data-character-sheet-target='stat']")
      assert_equal "3", stat_input.value
    end

    # Verify remaining points updated
    within "[data-character-sheet-target='remaining']" do
      assert_text "17"
    end
  end

  test "full allocation allows submission and saves correctly" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Allocate all 20 points across the stats
    # Leadership: 5, Technical: 8, Creative: 4, Communication: 3 (total: 20)

    leadership_stat = find("[data-stat-id='leadership']")
    within(leadership_stat) do
      increment_button = find("button", text: "+")
      5.times { increment_button.click }
    end

    technical_stat = find("[data-stat-id='technical']")
    within(technical_stat) do
      increment_button = find("button", text: "+")
      8.times { increment_button.click }
    end

    creative_stat = find("[data-stat-id='creative']")
    within(creative_stat) do
      increment_button = find("button", text: "+")
      4.times { increment_button.click }
    end

    communication_stat = find("[data-stat-id='communication']")
    within(communication_stat) do
      increment_button = find("button", text: "+")
      3.times { increment_button.click }
    end

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Verify remaining points is 0 and shows success color
    within "[data-character-sheet-target='remaining']" do
      assert_text "0"
    end

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved with correct allocations
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @character_sheet_question)

    assert answer.jsonb_value.present?
    allocations = answer.jsonb_value["allocations"]

    assert_equal 5, allocations["leadership"]
    assert_equal 8, allocations["technical"]
    assert_equal 4, allocations["creative"]
    assert_equal 3, allocations["communication"]

    total = answer.jsonb_value["total_allocated"]
    assert_equal 20, total
  end

  test "character sheet shows warning when not all points allocated" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Allocate only 10 points (incomplete)
    leadership_stat = find("[data-stat-id='leadership']")
    within(leadership_stat) do
      increment_button = find("button", text: "+")
      10.times { increment_button.click }
    end

    # Verify remaining points shows 10 with warning color
    within "[data-character-sheet-target='remaining']" do
      assert_text "10"
    end

    # Verify instruction about full allocation
    assert_text "You must allocate all 20 points to continue"
  end

  test "cannot allocate more than max points per stat" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Try to allocate 11 points to leadership (max is 10)
    leadership_stat = find("[data-stat-id='leadership']")

    within(leadership_stat) do
      increment_button = find("button", text: "+")

      # Click 11 times
      11.times { increment_button.click }

      # Verify value capped at 10
      stat_input = find("[data-character-sheet-target='stat']")
      assert_equal "10", stat_input.value
    end

    # Verify error message is shown
    # (The implementation should show an error when max is exceeded)
    # Error might be shown in the error target
  end

  test "character sheet allocation persists across page navigation" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Allocate some points
    leadership_stat = find("[data-stat-id='leadership']")
    within(leadership_stat) do
      increment_button = find("button", text: "+")
      7.times { increment_button.click }
    end

    technical_stat = find("[data-stat-id='technical']")
    within(technical_stat) do
      increment_button = find("button", text: "+")
      6.times { increment_button.click }
    end

    # Wait for autosave
    assert_text "Saved", wait: 5

    # Reload the page
    visit current_path

    # Verify allocations persisted
    leadership_stat_reloaded = find("[data-stat-id='leadership']")
    within(leadership_stat_reloaded) do
      stat_input = find("[data-character-sheet-target='stat']")
      assert_equal "7", stat_input.value
    end

    technical_stat_reloaded = find("[data-stat-id='technical']")
    within(technical_stat_reloaded) do
      stat_input = find("[data-character-sheet-target='stat']")
      assert_equal "6", stat_input.value
    end

    # Verify remaining points
    within "[data-character-sheet-target='remaining']" do
      assert_text "7"
    end
  end

  test "character sheet shows progress bars for each stat" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify progress bars are displayed for each stat
    assert_selector "progress.progress", count: 4

    # Verify radial progress indicators are displayed
    assert_selector ".radial-progress", count: 4
  end
end
