module Responses
  class SaveAnswer
    def initialize(answer, answer_params)
      @answer = answer
      @answer_params = answer_params
    end

    def call
      # Assign attributes based on question type
      assign_answer_value

      if @answer.save
        { success: true, answer: @answer }
      else
        { success: false, errors: @answer.errors.full_messages }
      end
    end

    private

    def assign_answer_value
      # The answer_params already contain the correct field (numeric_value, jsonb_value, etc.)
      # Rails strong parameters ensure only permitted fields are present
      @answer.assign_attributes(@answer_params)
    end
  end
end
