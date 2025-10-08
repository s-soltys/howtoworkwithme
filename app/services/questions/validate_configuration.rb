module Questions
  class ValidateConfiguration
    def initialize(question)
      @question = question
    end

    def call
      # Validate question settings based on question type
      # This is called before saving a question to ensure settings are valid
      return { success: true } unless @question.settings.present?

      case @question.question_type
      when "slider"
        validate_slider_settings
      when "swipe_yes_no"
        validate_swipe_yes_no_settings
      when "card_sort"
        validate_card_sort_settings
      when "energy_map"
        validate_energy_map_settings
      when "emoji_reaction"
        validate_emoji_reaction_settings
      when "character_sheet"
        validate_character_sheet_settings
      else
        { success: true }
      end
    end

    private

    def validate_slider_settings
      # Validation is handled by Question model validations
      # This service can add additional business logic if needed
      { success: true }
    end

    def validate_swipe_yes_no_settings
      { success: true }
    end

    def validate_card_sort_settings
      { success: true }
    end

    def validate_energy_map_settings
      { success: true }
    end

    def validate_emoji_reaction_settings
      { success: true }
    end

    def validate_character_sheet_settings
      { success: true }
    end
  end
end
