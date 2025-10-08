module Questionnaires
  class LockConfiguration
    class Result
      attr_reader :questionnaire, :errors

      def initialize(questionnaire:, success:, errors: [])
        @questionnaire = questionnaire
        @success = success
        @errors = errors
      end

      def success?
        @success
      end
    end

    def self.call(questionnaire)
      new(questionnaire).call
    end

    def initialize(questionnaire)
      @questionnaire = questionnaire
      @errors = []
    end

    def call
      return failure("Questionnaire must be persisted") unless @questionnaire.persisted?

      # If already locked, return success (idempotent)
      return success if @questionnaire.locked_at.present?

      # Lock the questionnaire
      if @questionnaire.update(locked_at: Time.current)
        success
      else
        failure("Failed to lock questionnaire: #{@questionnaire.errors.full_messages.join(', ')}")
      end
    end

    private

    def success
      Result.new(questionnaire: @questionnaire, success: true, errors: @errors)
    end

    def failure(message)
      @errors << message
      Result.new(questionnaire: @questionnaire, success: false, errors: @errors)
    end
  end
end
