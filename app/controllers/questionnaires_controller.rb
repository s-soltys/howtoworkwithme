class QuestionnairesController < ApplicationController
  # GET /questionnaires/:unique_token
  def show
    @questionnaire = Questionnaire.find_by!(unique_token: params[:unique_token])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # POST /questionnaires/:unique_token/start
  def start
    @questionnaire = Questionnaire.find_by!(unique_token: params[:unique_token])

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
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  rescue ActiveRecord::RecordInvalid => e
    @questionnaire = Questionnaire.find_by(unique_token: params[:unique_token])
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end
end
