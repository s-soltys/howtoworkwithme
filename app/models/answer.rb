class Answer < ApplicationRecord
  # Associations
  belongs_to :response
  belongs_to :question
  belongs_to :selected_option, class_name: "QuestionOption", optional: true

  # Validations
  validate :answer_matches_question_type
  validate :selected_options_exist
  validate :slider_value_valid
  validate :card_sort_value_valid
  validate :energy_map_value_valid
  validate :emoji_reaction_value_valid
  validate :character_sheet_value_valid

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
    when "slider"
      if question.required? && numeric_value.blank?
        errors.add(:numeric_value, "must be present for required slider questions")
      end
    when "swipe_yes_no"
      if question.required? && boolean_value.nil?
        errors.add(:boolean_value, "must be present for required swipe yes/no questions")
      end
    when "card_sort"
      if question.required? && (jsonb_value.blank? || jsonb_value["ranked"].blank?)
        errors.add(:jsonb_value, "must include at least one ranked card for required card sort questions")
      end
    when "energy_map"
      if question.required? && (jsonb_value.blank? || jsonb_value["data_points"].blank?)
        errors.add(:jsonb_value, "must include at least one data point for required energy map questions")
      end
    when "emoji_reaction"
      if question.required? && (jsonb_value.blank? || jsonb_value["emoji"].blank?)
        errors.add(:jsonb_value, "must include selected emoji for required emoji reaction questions")
      end
    when "character_sheet"
      if question.required? && (jsonb_value.blank? || jsonb_value["allocations"].blank?)
        errors.add(:jsonb_value, "must include stat allocations for required character_sheet questions")
      end
    end
  end

  def selected_options_exist
    return unless question&.question_type.in?([ "single_choice", "multiple_choice" ])

    available_option_ids = question.question_options.pluck(:id)

    if question.single_choice? && selected_option_id.present?
      errors.add(:selected_option_id, "must be a valid option for this question") unless available_option_ids.include?(selected_option_id)
    elsif question.multiple_choice? && selected_option_ids.present?
      invalid_ids = selected_option_ids - available_option_ids
      errors.add(:selected_option_ids, "contains invalid option IDs: #{invalid_ids.join(', ')}") if invalid_ids.any?
    end
  end

  # Validation methods for new question types

  def slider_value_valid
    return unless question&.slider? && numeric_value.present?

    min = question.settings["min_value"]
    max = question.settings["max_value"]

    if min && numeric_value < min
      errors.add(:numeric_value, "must be at least #{min}")
    end

    if max && numeric_value > max
      errors.add(:numeric_value, "must be at most #{max}")
    end
  end

  def card_sort_value_valid
    return unless question&.card_sort? && jsonb_value.present?

    valid_card_ids = question.settings["cards"]&.map { |c| c["id"] } || []
    ranked = jsonb_value["ranked"] || []
    unranked = jsonb_value["unranked"] || []

    # Check all IDs are valid
    all_ids = ranked.map { |r| r["id"] } + unranked
    invalid_ids = all_ids - valid_card_ids

    if invalid_ids.any?
      errors.add(:jsonb_value, "contains invalid card IDs: #{invalid_ids.join(', ')}")
    end

    # Check for duplicates
    if all_ids.uniq.size != all_ids.size
      errors.add(:jsonb_value, "contains duplicate card IDs")
    end

    # Check ranks are sequential
    ranks = ranked.map { |r| r["rank"] }
    expected_ranks = (1..ranks.size).to_a
    if ranks.sort != expected_ranks
      errors.add(:jsonb_value, "ranks must be sequential starting from 1")
    end
  end

  def energy_map_value_valid
    return unless question&.energy_map? && jsonb_value.present?

    valid_periods = question.settings["time_periods"] || []
    scale_min = question.settings["scale_min"] || 0
    scale_max = question.settings["scale_max"] || 10
    data_points = jsonb_value["data_points"] || []

    data_points.each do |point|
      period = point["period"]
      value = point["value"]

      unless valid_periods.include?(period)
        errors.add(:jsonb_value, "contains invalid time period: #{period}")
      end

      if value.present? && (value < scale_min || value > scale_max)
        errors.add(:jsonb_value, "energy value #{value} for #{period} must be between #{scale_min} and #{scale_max}")
      end
    end

    # Check for duplicate periods
    periods = data_points.map { |p| p["period"] }
    if periods.uniq.size != periods.size
      errors.add(:jsonb_value, "contains duplicate time periods")
    end
  end

  def emoji_reaction_value_valid
    return unless question&.emoji_reaction? && jsonb_value.present?

    valid_emojis = question.settings["emoji_options"]&.map { |o| o["emoji"] } || []
    selected_emoji = jsonb_value["emoji"]

    unless valid_emojis.include?(selected_emoji)
      errors.add(:jsonb_value, "selected emoji is not a valid option")
    end
  end

  def character_sheet_value_valid
    return unless question&.character_sheet? && jsonb_value.present?

    total_points = question.settings["total_points"]
    stats = question.settings["stats"] || []
    allocations = jsonb_value["allocations"] || {}
    total_allocated = jsonb_value["total_allocated"]

    # Check all stats have allocations
    stat_ids = stats.map { |s| s["id"] }
    missing_stats = stat_ids - allocations.keys
    if missing_stats.any?
      errors.add(:jsonb_value, "missing allocations for stats: #{missing_stats.join(', ')}")
    end

    # Check no invalid stats
    invalid_stats = allocations.keys - stat_ids
    if invalid_stats.any?
      errors.add(:jsonb_value, "contains invalid stat IDs: #{invalid_stats.join(', ')}")
    end

    # Check each stat allocation is within bounds
    stats.each do |stat|
      stat_id = stat["id"]
      allocation = allocations[stat_id]
      min = stat["min"] || 0
      max = stat["max"] || 10

      if allocation.present?
        if allocation < min
          errors.add(:jsonb_value, "#{stat_id} allocation must be at least #{min}")
        elsif allocation > max
          errors.add(:jsonb_value, "#{stat_id} allocation must be at most #{max}")
        end
      end
    end

    # Check total allocation (per FR-018: must allocate all points)
    actual_total = allocations.values.sum
    if total_allocated != actual_total
      errors.add(:jsonb_value, "total_allocated (#{total_allocated}) does not match sum of allocations (#{actual_total})")
    end

    if actual_total != total_points
      errors.add(:jsonb_value, "must allocate all #{total_points} points (currently allocated: #{actual_total})")
    end
  end
end
