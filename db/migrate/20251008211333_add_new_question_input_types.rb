class AddNewQuestionInputTypes < ActiveRecord::Migration[8.0]
  def up
    # Add new enum values to question_type
    # Rails 8 approach: no enum type in DB, just string values

    # Validate existing data before migration
    Question.where.not(question_type: ["text", "single_choice", "multiple_choice", "yes_no"]).each do |q|
      raise "Invalid question_type found: #{q.question_type} for Question ID #{q.id}"
    end

    # No schema change needed - enum is managed in model
    # This migration serves as documentation and checkpoint
  end

  def down
    # Remove questions with new types before downgrading
    Question.where(question_type: ["slider", "swipe_yes_no", "card_sort", "energy_map", "emoji_reaction", "character_sheet"]).destroy_all
  end
end
