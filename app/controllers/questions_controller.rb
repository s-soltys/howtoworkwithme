class QuestionsController < ApplicationController
  before_action :set_category_and_check_locked, only: [ :create ]
  before_action :set_question, only: [ :update, :destroy ]
  before_action :check_question_questionnaire_not_locked, only: [ :update, :destroy ]

  # POST /categories/:category_id/questions
  def create
    @question = @category.questions.new(question_params)

    respond_to do |format|
      if @question.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "category_#{@category.id}_questions",
            partial: "questions/question",
            locals: { question: @question }
          )
        end
        format.html { redirect_to edit_questionnaire_path(@category.questionnaire.unique_token), notice: "Question created successfully" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "question_form_errors",
            partial: "shared/errors",
            locals: { object: @question }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to edit_questionnaire_path(@category.questionnaire.unique_token), alert: "Failed to create question" }
      end
    end
  end

  # PATCH /questions/:id
  def update
    respond_to do |format|
      if @question.update(question_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "question_#{@question.id}",
            partial: "questions/question",
            locals: { question: @question }
          )
        end
        format.html { redirect_to edit_questionnaire_path(@question.category.questionnaire.unique_token), notice: "Question updated successfully" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "question_form_errors",
            partial: "shared/errors",
            locals: { object: @question }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to edit_questionnaire_path(@question.category.questionnaire.unique_token), alert: "Failed to update question" }
      end
    end
  end

  # DELETE /questions/:id
  def destroy
    @question.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("question_#{@question.id}")
      end
      format.html { redirect_to edit_questionnaire_path(@question.category.questionnaire.unique_token), notice: "Question deleted successfully" }
    end
  end

  private

  def set_category_and_check_locked
    @category = Category.find(params[:category_id])

    if @category.questionnaire.locked?
      respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html { redirect_to organization_path(@category.questionnaire.organization.unique_token), alert: "Questionnaire is locked" }
      end
      false
    end
  end

  def set_question
    @question = Question.find(params[:id])
  end

  def check_question_questionnaire_not_locked
    if @question.category.questionnaire.locked?
      respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html { redirect_to organization_path(@question.category.questionnaire.organization.unique_token), alert: "Questionnaire is locked" }
      end
      false
    end
  end

  def question_params
    params.require(:question).permit(
      :text,
      :question_type,
      :position,
      :required,
      :settings,
      question_options_attributes: [ :id, :text, :position, :_destroy ]
    )
  end
end
