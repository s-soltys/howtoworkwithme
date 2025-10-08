class Answer < ApplicationRecord
  # Associations
  belongs_to :response
  belongs_to :question
  belongs_to :selected_option, class_name: "QuestionOption", optional: true

  # Validations
  validate :answer_matches_question_type
  validate :selected_options_exist

  private

  def answer_matches_question_type
    return unless question

    case question.question_type
    when "text"
      if question.required? && text_value.blank?
        errors.add(:text_value, "must be present for required text questions")
      end
      errors.add(:text_value, "must be 1000 characters or less") if text_value.present? && text_value.length > 1000
    when "single_choice"
      if question.required? && selected_option_id.blank?
        errors.add(:selected_option_id, "must be present for required single choice questions")
      end
    when "multiple_choice"
      if question.required? && (selected_option_ids.blank? || selected_option_ids.empty?)
        errors.add(:selected_option_ids, "must be present for required multiple choice questions")
      end
    when "yes_no"
      if question.required? && boolean_value.nil?
        errors.add(:boolean_value, "must be present for required yes/no questions")
      end
    end
  end

  def selected_options_exist
    return unless question&.question_type.in?(["single_choice", "multiple_choice"])

    available_option_ids = question.question_options.pluck(:id)

    if question.single_choice? && selected_option_id.present?
      errors.add(:selected_option_id, "must be a valid option for this question") unless available_option_ids.include?(selected_option_id)
    elsif question.multiple_choice? && selected_option_ids.present?
      invalid_ids = selected_option_ids - available_option_ids
      errors.add(:selected_option_ids, "contains invalid option IDs: #{invalid_ids.join(', ')}") if invalid_ids.any?
    end
  end
end
