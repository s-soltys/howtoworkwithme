class ResponsesController < ApplicationController
  before_action :find_response, only: [:edit, :update, :submit]

  # GET /responses/:unique_token/edit
  def edit
    # Questionnaire and associations are eager loaded in find_response
    @questionnaire = @response.questionnaire
  end

  # PATCH /responses/:unique_token (autosave)
  def update
    # Manually handle answer updates to avoid duplicates
    if params[:response][:answers_attributes]
      params[:response][:answers_attributes].each do |_key, answer_params|
        next unless answer_params[:question_id]

        answer = @response.answers.find_or_initialize_by(question_id: answer_params[:question_id])
        # Permit only the allowed attributes
        permitted_params = answer_params.permit(:text_value, :selected_option_id, :boolean_value, selected_option_ids: [])
        answer.assign_attributes(permitted_params)
        answer.save if answer.changed?
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "autosave_status",
          partial: "responses/autosave_status",
          locals: { status: "saved" }
        )
      end
      format.html { redirect_to edit_response_path(@response.unique_token), notice: "Draft saved" }
    end
  rescue => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "autosave_status",
          partial: "responses/autosave_status",
          locals: { status: "error", message: e.message }
        )
      end
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  # POST /responses/:unique_token/submit
  def submit
    result = Responses::SubmitFinal.new(@response).call

    if result[:success]
      redirect_to profile_path(result[:profile].unique_token), notice: "Questionnaire submitted successfully!"
    else
      flash.now[:alert] = result[:error]
      @questionnaire = @response.questionnaire
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_response
    @response = Response.includes(questionnaire: { categories: { questions: :question_options } })
                        .find_by!(unique_token: params[:unique_token])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  def response_params
    params.require(:response).permit(
      answers_attributes: [:id, :question_id, :text_value, :selected_option_id, :boolean_value, selected_option_ids: []]
    )
  end
end
