module QuestionnairesHelper
  # Format answer for display based on question type
  def format_answer(answer)
    return "" if answer.nil?

    case answer.question.question_type
    when "text"
      answer.text_value || ""
    when "single_choice"
      answer.selected_option&.text || ""
    when "multiple_choice"
      if answer.selected_option_ids.present?
        options = QuestionOption.where(id: answer.selected_option_ids)
        options.map(&:text).join(", ")
      else
        ""
      end
    when "yes_no"
      answer.boolean_value.nil? ? "" : (answer.boolean_value ? "Yes" : "No")
    else
      ""
    end
  end

  # Group questions by category for table header
  def questions_by_category(categories)
    categories.each_with_object({}) do |category, hash|
      hash[category] = category.questions.order(:position)
    end
  end

  # Find answer for a specific question in a response
  def find_answer(response, question)
    response.answers.find { |answer| answer.question_id == question.id }
  end
end
