require "application_system_test_case"

class EnergyMappingTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @organization = Organization.create!(name: "Test Corp")
    @questionnaire = @organization.questionnaires.create!(
      title: "Energy Patterns",
      description: "Map your energy throughout the week"
    )

    @category = @questionnaire.categories.create!(name: "Work Patterns", position: 1)

    # Create energy map question
    @energy_map_question = @category.questions.create!(
      question_type: "energy_map",
      text: "What are your typical energy levels throughout the work week?",
      position: 1,
      required: true,
      settings: {
        "time_periods" => [
          "Monday Morning",
          "Monday Afternoon",
          "Tuesday Morning",
          "Tuesday Afternoon",
          "Wednesday Morning",
          "Wednesday Afternoon",
          "Thursday Morning",
          "Thursday Afternoon",
          "Friday Morning",
          "Friday Afternoon"
        ],
        "scale_min" => 0,
        "scale_max" => 10,
        "scale_labels" => {
          "0" => "Exhausted",
          "5" => "Moderate",
          "10" => "Energized"
        },
        "y_axis_label" => "Energy Level",
        "allow_partial" => true
      }
    )
  end

  test "employee sees energy map question with chart canvas" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify energy map question is displayed
    assert_text "What are your typical energy levels throughout the work week?"
    assert_text "Drag the points up or down to set your energy level for each time period"

    # Verify canvas element is present
    assert_selector "[data-energy-map-target='canvas']"

    # Verify the energy map controller is initialized
    assert_selector "[data-controller='energy-map']"
  end

  test "energy map has correct configuration from settings" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Get the energy map controller element
    energy_map = find("[data-controller='energy-map']")

    # Verify data attributes are set correctly
    labels = JSON.parse(energy_map["data-energy-map-labels-value"])
    assert_equal 10, labels.length
    assert_includes labels, "Monday Morning"
    assert_includes labels, "Friday Afternoon"

    scale_min = energy_map["data-energy-map-scale-min-value"]
    scale_max = energy_map["data-energy-map-scale-max-value"]
    assert_equal "0", scale_min
    assert_equal "10", scale_max
  end

  test "energy map can be submitted with data points" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Simulate setting energy data points via JavaScript
    # (Chart.js interaction is complex to test with Capybara, so we test data submission)
    page.execute_script(<<~JS)
      const hiddenInput = document.querySelector('[data-energy-map-target="hiddenInput"]');
      const energyData = {
        data_points: [
          { period: "Monday Morning", value: 7 },
          { period: "Monday Afternoon", value: 5 },
          { period: "Tuesday Morning", value: 8 },
          { period: "Tuesday Afternoon", value: 6 },
          { period: "Wednesday Morning", value: 7 },
          { period: "Wednesday Afternoon", value: 4 },
          { period: "Thursday Morning", value: 6 },
          { period: "Thursday Afternoon", value: 5 },
          { period: "Friday Morning", value: 8 },
          { period: "Friday Afternoon", value: 3 }
        ]
      };
      hiddenInput.value = JSON.stringify(energyData);
      hiddenInput.dispatchEvent(new Event('change', { bubbles: true }));
    JS

    # Wait a moment for the change to register
    sleep 0.5

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify answer was saved with energy data
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @energy_map_question)

    assert answer.jsonb_value.present?
    data_points = answer.jsonb_value["data_points"]
    assert_equal 10, data_points.length

    # Verify first and last data points
    assert_equal "Monday Morning", data_points[0]["period"]
    assert_equal 7, data_points[0]["value"]
    assert_equal "Friday Afternoon", data_points[9]["period"]
    assert_equal 3, data_points[9]["value"]
  end

  test "energy map allows partial data with null values" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Simulate partial energy data (some periods have null values)
    page.execute_script(<<~JS)
      const hiddenInput = document.querySelector('[data-energy-map-target="hiddenInput"]');
      const energyData = {
        data_points: [
          { period: "Monday Morning", value: 7 },
          { period: "Monday Afternoon", value: null },
          { period: "Tuesday Morning", value: 8 },
          { period: "Tuesday Afternoon", value: null },
          { period: "Wednesday Morning", value: null },
          { period: "Wednesday Afternoon", value: null },
          { period: "Thursday Morning", value: null },
          { period: "Thursday Afternoon", value: null },
          { period: "Friday Morning", value: 8 },
          { period: "Friday Afternoon", value: null }
        ]
      };
      hiddenInput.value = JSON.stringify(energyData);
    JS

    sleep 0.5

    # Submit questionnaire
    accept_confirm do
      click_button "Submit Questionnaire"
    end

    # Verify partial answer was saved
    response = @questionnaire.responses.last
    answer = response.answers.find_by(question: @energy_map_question)

    data_points = answer.jsonb_value["data_points"]

    # Check some values are set and others are null
    assert_equal 7, data_points[0]["value"]
    assert_nil data_points[1]["value"]
    assert_equal 8, data_points[2]["value"]
  end

  test "energy map shows helpful instruction text" do
    # Visit questionnaire and start
    visit questionnaire_path(@questionnaire.unique_token)
    fill_in "employee_name", with: "Test User"
    click_button "Start Questionnaire"

    # Verify instruction text
    assert_text "Drag the points up or down to set your energy level"
    assert_text "Click on the chart to add a point"
    assert_text "Tip: Set at least one data point to save your answer"
  end
end
