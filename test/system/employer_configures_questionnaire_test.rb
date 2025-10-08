require "application_system_test_case"

class EmployerConfiguresQuestionnaireTest < ApplicationSystemTestCase
  setup do
    @organization = organizations(:one)
    @questionnaire = questionnaires(:one)
  end

  test "employer creates categories" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Add first category
    click_on "Add Category"
    fill_in "Category name", with: "Work Style"
    click_button "Save Category"

    assert_text "Work Style"
    assert_text "Category created successfully"

    # Add second category
    click_on "Add Category"
    fill_in "Category name", with: "Communication Preferences"
    click_button "Save Category"

    assert_text "Communication Preferences"
  end

  test "employer adds different question types" do
    @category = categories(:one)
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Add text question
    within("#category_#{@category.id}") do
      click_on "Add Question"
    end

    fill_in "Question text", with: "What are your working hours?"
    select "Free Text", from: "Question type"
    check "Required"
    click_button "Save Question"

    assert_text "What are your working hours?"

    # Add single choice question
    within("#category_#{@category.id}") do
      click_on "Add Question"
    end

    fill_in "Question text", with: "What is your preferred communication method?"
    select "Single Choice", from: "Question type"

    # Add options
    fill_in "Option 1", with: "Email"
    click_on "Add Option"
    fill_in "Option 2", with: "Slack"
    click_on "Add Option"
    fill_in "Option 3", with: "Phone"

    click_button "Save Question"

    assert_text "What is your preferred communication method?"
    assert_text "Email"
    assert_text "Slack"
    assert_text "Phone"

    # Add multiple choice question
    within("#category_#{@category.id}") do
      click_on "Add Question"
    end

    fill_in "Question text", with: "Which tools do you use?"
    select "Multiple Choice", from: "Question type"

    fill_in "Option 1", with: "Jira"
    click_on "Add Option"
    fill_in "Option 2", with: "Trello"

    click_button "Save Question"

    assert_text "Which tools do you use?"

    # Add yes/no question
    within("#category_#{@category.id}") do
      click_on "Add Question"
    end

    fill_in "Question text", with: "Do you prefer async communication?"
    select "Yes/No", from: "Question type"

    click_button "Save Question"

    assert_text "Do you prefer async communication?"
  end

  test "employer reorders categories and questions" do
    @category1 = categories(:one)
    @category2 = categories(:two)

    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Verify initial order
    categories = page.all(".category-card").map { |c| c.text }
    assert_equal @category1.name, categories.first

    # Reorder categories (this would use drag-and-drop in real UI, but for test we'll use position update)
    within("#category_#{@category2.id}") do
      click_on "Edit"
    end

    fill_in "Position", with: "1"
    click_button "Save Category"

    # Category 2 should now be first
    categories = page.all(".category-card").map { |c| c.text }
    assert_equal @category2.name, categories.first
  end

  test "configuration persists across visits" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Add category and question
    click_on "Add Category"
    fill_in "Category name", with: "Test Category"
    click_button "Save Category"

    # Leave page and return
    visit root_path
    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Verify persistence
    assert_text "Test Category"
  end

  test "employer generates employee link" do
    visit edit_questionnaire_path(@questionnaire.unique_token)

    click_on "Generate Employee Link"

    # Should see the shareable link
    assert_selector "[data-testid='employee-link']"
    assert_text questionnaire_url(@questionnaire.unique_token)
  end

  test "locked questionnaire prevents editing" do
    # Lock the questionnaire by having an employee submit a response
    @questionnaire.update!(locked_at: Time.current)

    visit edit_questionnaire_path(@questionnaire.unique_token)

    # Should see locked indicator
    assert_text "This questionnaire is locked"

    # Buttons should be disabled
    assert_selector "button[disabled]", text: "Add Category"
  end
end
