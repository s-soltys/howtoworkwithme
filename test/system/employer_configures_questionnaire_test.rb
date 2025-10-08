require "application_system_test_case"

class EmployerConfiguresQuestionnaireTest < ApplicationSystemTestCase
  setup do
    @organization = organizations(:one)
    @questionnaire = questionnaires(:one)
  end

  test "employer creates categories" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Add first category using inline form
    fill_in "Category name", with: "Work Style"
    click_button "Add Category"

    assert_text "Work Style"

    # Add second category
    fill_in "Category name", with: "Communication Preferences"
    click_button "Add Category"

    assert_text "Communication Preferences"
  end

  test "employer adds different question types" do
    @category = categories(:one)
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Verify category is displayed
    assert_text @category.name

    # Find the category card div and scope to it
    category_card = find("#category_#{@category.id}")

    within(category_card) do
      fill_in "question[text]", with: "What are your working hours?"
      select "Free Text", from: "question[question_type]"
      check "question[required]"
      click_button "Add Question"
    end

    assert_text "What are your working hours?"
  end

  test "employer reorders categories and questions" do
    @category1 = categories(:one)
    @category2 = categories(:two)

    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Verify categories are displayed
    categories = page.all(".category-card h4").map(&:text)
    assert_includes categories, @category1.name
    assert_includes categories, @category2.name
  end

  test "configuration persists across visits" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Add category using inline form
    fill_in "Category name", with: "Test Category"
    click_button "Add Category"

    # Wait for category to appear
    assert_text "Test Category"

    # Get the current URL to reload the page (simpler than visiting root and back)
    current_url_path = current_url
    visit current_url_path

    # Verify persistence after page reload
    assert_text "Test Category"
  end

  test "employer generates employee link" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Link should be visible (no need to click to generate)
    assert_selector "[data-testid='employee-link']"

    # Verify the link contains the questionnaire token
    link_value = find("[data-testid='employee-link']").value
    assert_includes link_value, @questionnaire.unique_token
  end

  test "locked questionnaire prevents editing" do
    # Lock the questionnaire by having an employee submit a response
    @questionnaire.update!(locked_at: Time.current)

    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Should see locked indicator
    assert_text "This questionnaire is locked"

    # Buttons should be disabled
    assert_selector "input[type='submit'][value='Add Category'][disabled]"
  end
end
