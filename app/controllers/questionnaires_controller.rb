class QuestionnairesController < ApplicationController
  before_action :set_questionnaire, only: [:show, :start, :edit, :generate_link, :responses]
  before_action :check_not_locked, only: [:edit]

  # GET /questionnaires/:unique_token
  def show
  end

  # GET /organizations/:organization_unique_token/questionnaires/new
  def new
    @organization = Organization.find_by!(unique_token: params[:organization_unique_token])
    @questionnaire = @organization.questionnaires.new
  end

  # POST /organizations/:organization_unique_token/questionnaires
  def create
    @organization = Organization.find_by!(unique_token: params[:organization_unique_token])
    @questionnaire = @organization.questionnaires.new(questionnaire_params)

    if @questionnaire.save
      redirect_to edit_questionnaire_path(@questionnaire.unique_token), notice: "Questionnaire created successfully"
    else
      redirect_to organization_path(@organization.unique_token), alert: "Failed to create questionnaire"
    end
  end

  # GET /questionnaires/:unique_token/edit
  def edit
    @categories = @questionnaire.categories.includes(questions: :question_options).order(:position)
  end

  # POST /questionnaires/:unique_token/start
  def start
    # Create employee (name from form)
    employee = @questionnaire.organization.employees.create!(
      name: params[:employee_name]
    )

    # Create draft response
    response = @questionnaire.responses.create!(
      employee: employee,
      status: "draft"
    )

    # Redirect to edit response
    redirect_to edit_response_path(response.unique_token)
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end

  # POST /questionnaires/:unique_token/generate_link
  def generate_link
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("employee_link_display",
          partial: "questionnaires/employee_link",
          locals: { questionnaire: @questionnaire })
      end
      format.html { redirect_to edit_questionnaire_path(@questionnaire.unique_token) }
    end
  end

  # GET /questionnaires/:unique_token/responses
  def responses
    # Get most recent response per employee
    @responses = @questionnaire.responses
      .submitted
      .includes(:employee, answers: [:question, :selected_option])
      .order(submitted_at: :desc)
      .group_by(&:employee_id)
      .map { |_, responses| responses.first }
  end

  private

  def set_questionnaire
    @questionnaire = Questionnaire.find_by!(unique_token: params[:unique_token])
  end

  def check_not_locked
    if @questionnaire.locked?
      flash[:alert] = "This questionnaire is locked and cannot be edited"
      redirect_to organization_path(@questionnaire.organization.unique_token)
    end
  end

  def questionnaire_params
    params.fetch(:questionnaire, {}).permit(:title, :description)
  end
end
