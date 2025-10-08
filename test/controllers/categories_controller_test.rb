require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @questionnaire = questionnaires(:one)
    @category = categories(:one)
  end

  test "should create category with Turbo Stream" do
    assert_difference("Category.count", 1) do
      post questionnaire_categories_path(@questionnaire.unique_token),
        params: { category: { name: "New Category", position: 1 } },
        as: :turbo_stream
    end

    assert_response :success
  end

  test "should not create category for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    assert_no_difference("Category.count") do
      post questionnaire_categories_path(@questionnaire.unique_token),
        params: { category: { name: "New Category" } },
        as: :turbo_stream
    end

    assert_response :forbidden
  end

  test "should update category with Turbo Stream" do
    patch category_path(@category),
      params: { category: { name: "Updated Name" } },
      as: :turbo_stream

    assert_response :success
    @category.reload
    assert_equal "Updated Name", @category.name
  end

  test "should not update category for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    patch category_path(@category),
      params: { category: { name: "Updated Name" } },
      as: :turbo_stream

    assert_response :forbidden
  end

  test "should destroy category with Turbo Stream" do
    assert_difference("Category.count", -1) do
      delete category_path(@category), as: :turbo_stream
    end

    assert_response :success
  end

  test "should not destroy category for locked questionnaire" do
    @questionnaire.update!(locked_at: Time.current)

    assert_no_difference("Category.count") do
      delete category_path(@category), as: :turbo_stream
    end

    assert_response :forbidden
  end
end
