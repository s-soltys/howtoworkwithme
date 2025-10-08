require "test_helper"

class QuestionnairesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
  end

  test "should get new questionnaire form" do
    get new_organization_questionnaire_path(@organization.unique_token)
    assert_response :success
    assert_select "h1", "Create Questionnaire"
    assert_select "input[name='questionnaire[title]']"
    assert_select "textarea[name='questionnaire[description]']"
  end

  test "should create questionnaire with valid data" do
    assert_difference("Questionnaire.count", 1) do
      post organization_questionnaires_path(@organization.unique_token), params: {
        questionnaire: {
          title: "New Questionnaire",
          description: "A test questionnaire"
        }
      }
    end

    questionnaire = Questionnaire.last
    assert_equal "New Questionnaire", questionnaire.title
    assert_equal "A test questionnaire", questionnaire.description
    assert_equal @organization.id, questionnaire.organization_id
    assert_redirected_to edit_questionnaire_path(questionnaire.unique_token)
  end

  test "should not create questionnaire without title" do
    assert_no_difference("Questionnaire.count") do
      post organization_questionnaires_path(@organization.unique_token), params: {
        questionnaire: {
          title: "",
          description: "A test questionnaire"
        }
      }
    end

    assert_redirected_to organization_path(@organization.unique_token)
  end

  test "should show questionnaire" do
    questionnaire = questionnaires(:one)
    get questionnaire_path(questionnaire.unique_token)
    assert_response :success
  end

  test "should get edit questionnaire page" do
    questionnaire = questionnaires(:unlocked_questionnaire)
    get edit_questionnaire_path(questionnaire.unique_token)
    assert_response :success
  end

  test "should redirect from edit when questionnaire is locked" do
    questionnaire = questionnaires(:locked_questionnaire)
    get edit_questionnaire_path(questionnaire.unique_token)
    assert_redirected_to organization_path(questionnaire.organization.unique_token)
  end
end
