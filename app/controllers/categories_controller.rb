class CategoriesController < ApplicationController
  before_action :set_questionnaire_and_check_locked, only: [ :create ]
  before_action :set_category, only: [ :update, :destroy ]
  before_action :check_category_questionnaire_not_locked, only: [ :update, :destroy ]

  # POST /questionnaires/:unique_token/categories
  def create
    @category = @questionnaire.categories.new(category_params)

    respond_to do |format|
      if @category.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "categories_list",
            partial: "categories/category_with_questions",
            locals: { category: @category, locked: @questionnaire.locked? }
          )
        end
        format.html { redirect_to edit_questionnaire_path(@questionnaire.unique_token), notice: "Category created successfully" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "category_form_errors",
            partial: "shared/errors",
            locals: { object: @category }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to edit_questionnaire_path(@questionnaire.unique_token), alert: "Failed to create category" }
      end
    end
  end

  # PATCH /categories/:id
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "category_#{@category.id}",
            partial: "categories/category",
            locals: { category: @category }
          )
        end
        format.html { redirect_to edit_questionnaire_path(@category.questionnaire.unique_token), notice: "Category updated successfully" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "category_form_errors",
            partial: "shared/errors",
            locals: { object: @category }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to edit_questionnaire_path(@category.questionnaire.unique_token), alert: "Failed to update category" }
      end
    end
  end

  # DELETE /categories/:id
  def destroy
    @category.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("category_#{@category.id}")
      end
      format.html { redirect_to edit_questionnaire_path(@category.questionnaire.unique_token), notice: "Category deleted successfully" }
    end
  end

  private

  def set_questionnaire_and_check_locked
    @questionnaire = Questionnaire.find_by!(unique_token: params[:questionnaire_unique_token])

    if @questionnaire.locked?
      respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html { redirect_to organization_path(@questionnaire.organization.unique_token), alert: "Questionnaire is locked" }
      end
      false
    end
  end

  def set_category
    @category = Category.find(params[:id])
  end

  def check_category_questionnaire_not_locked
    if @category.questionnaire.locked?
      respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html { redirect_to organization_path(@category.questionnaire.organization.unique_token), alert: "Questionnaire is locked" }
      end
      false
    end
  end

  def category_params
    params.require(:category).permit(:name, :position)
  end
end
