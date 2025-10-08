module Responses
  class SubmitFinal
    def initialize(response)
      @response = response
      @questionnaire = response.questionnaire
    end

    def call
      # Reload to get current database state with associations
      @response = Response.includes(answers: :question, questionnaire: :questions)
                          .find(@response.id)
      @questionnaire = @response.questionnaire

      # Validate all required questions are answered
      unless all_required_questions_answered?
        return { success: false, error: "Please answer all required questions" }
      end

      ActiveRecord::Base.transaction do
        # Update response status to submitted
        @response.update!(status: "submitted", submitted_at: Time.current)

        # Lock questionnaire if this is the first submission
        lock_result = Questionnaires::LockConfiguration.call(@questionnaire)
        unless lock_result.success?
          raise ActiveRecord::RecordInvalid.new(@questionnaire)
        end

        # Generate profile with unique token
        profile = @response.create_profile!

        { success: true, profile: profile, response: @response }
      end
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    rescue => e
      { success: false, error: "An error occurred: #{e.message}" }
    end

    private

    def all_required_questions_answered?
      # Get all required questions from the questionnaire
      required_questions = @questionnaire.questions.where(required: true)

      required_questions.all? do |question|
        answer = @response.answers.find { |a| a.question_id == question.id }
        next false unless answer

        # Check if the answer has a value based on question type
        case question.question_type
        when "text"
          answer.text_value.present?
        when "single_choice"
          answer.selected_option_id.present?
        when "multiple_choice"
          answer.selected_option_ids.present? && answer.selected_option_ids.any?
        when "yes_no"
          !answer.boolean_value.nil?
        else
          false
        end
      end
    end
  end
end
