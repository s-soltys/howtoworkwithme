module Responses
  class ValidateCharacterSheet
    def initialize(answer)
      @answer = answer
      @question = answer.question
    end

    def call
      return { success: false, error: "Not a character sheet question" } unless @question.character_sheet?

      allocations = @answer.jsonb_value["allocations"] || {}
      total_points = @question.settings["total_points"]
      stats = @question.settings["stats"] || []

      # Validate total points allocated
      total_allocated = allocations.values.sum
      if total_allocated != total_points
        return {
          success: false,
          error: "Must allocate exactly #{total_points} points (currently allocated: #{total_allocated})"
        }
      end

      # Validate each stat is within min/max bounds
      stats.each do |stat|
        stat_id = stat["id"]
        allocation = allocations[stat_id]
        min = stat["min"] || 0
        max = stat["max"] || 10

        if allocation.nil?
          return { success: false, error: "Missing allocation for #{stat['label']}" }
        end

        if allocation < min || allocation > max
          return {
            success: false,
            error: "#{stat['label']} must be between #{min} and #{max} points"
          }
        end
      end

      { success: true }
    end
  end
end
