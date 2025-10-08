class ProfilesController < ApplicationController
  # GET /profiles/:unique_token
  def show
    @profile = Profile.includes(response: { answers: { question: [ :category, :question_options ] }, questionnaire: :categories }).find_by!(unique_token: params[:unique_token])
    @profile.increment_view_count!

    @response = @profile.response
    @questionnaire = @response.questionnaire
    @employee = @response.employee
  end
end
