class Question < ApplicationRecord
  # Enums
  enum :question_type, {
    text: "text",
    single_choice: "single_choice",
    multiple_choice: "multiple_choice",
    yes_no: "yes_no",
    slider: "slider",
    swipe_yes_no: "swipe_yes_no",
    card_sort: "card_sort",
    energy_map: "energy_map",
    emoji_reaction: "emoji_reaction",
    character_sheet: "character_sheet"
  }

  # Associations
  belongs_to :category
  has_many :question_options, -> { order(position: :asc) }, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_one :questionnaire, through: :category

  # Callbacks
  before_validation :set_position, on: :create

  # Validations
  validates :text, presence: true
  validates :question_type, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :choice_questions_need_options, if: :persisted?
  validate :questionnaire_not_locked, on: [ :create, :update, :destroy ]

  # New question type validations
  validate :slider_settings_valid, if: :slider?
  validate :swipe_yes_no_settings_valid, if: :swipe_yes_no?
  validate :card_sort_settings_valid, if: :card_sort?
  validate :energy_map_settings_valid, if: :energy_map?
  validate :emoji_reaction_settings_valid, if: :emoji_reaction?
  validate :character_sheet_settings_valid, if: :character_sheet?

  # Nested attributes
  accepts_nested_attributes_for :question_options, allow_destroy: true, reject_if: proc { |attrs| attrs[:text].blank? }

  private

  def set_position
    return if position.present?
    self.position = (category.questions.maximum(:position) || 0) + 1
  end

  def choice_questions_need_options
    return unless single_choice? || multiple_choice?

    # Count both persisted and new options (excluding marked for destruction)
    total_options = question_options.reject(&:marked_for_destruction?).size

    if total_options < 2
      errors.add(:base, "Choice questions must have at least 2 options")
    end
  end

  def questionnaire_not_locked
    if category&.questionnaire&.locked?
      errors.add(:base, "Cannot modify question when questionnaire is locked")
    end
  end

  # Validation methods for new question types

  def slider_settings_valid
    return unless settings.present?

    min = settings["min_value"]
    max = settings["max_value"]
    step = settings["step"] || 1

    errors.add(:settings, "must include min_value") if min.blank?
    errors.add(:settings, "must include max_value") if max.blank?
    errors.add(:settings, "min_value must be less than max_value") if min && max && min >= max
    errors.add(:settings, "step must be positive") if step && step <= 0
  end

  def swipe_yes_no_settings_valid
    return unless settings.present?

    threshold = settings["swipe_threshold"]
    duration = settings["animation_duration"]

    errors.add(:settings, "swipe_threshold must be between 0.0 and 1.0") if threshold && !threshold.between?(0.0, 1.0)
    errors.add(:settings, "animation_duration must be positive") if duration && duration <= 0
  end

  def card_sort_settings_valid
    return unless settings.present?

    cards = settings["cards"]
    errors.add(:settings, "must include cards array") if cards.blank?
    errors.add(:settings, "must have between 3 and 15 cards") if cards && !cards.size.between?(3, 15)

    if cards.present?
      ids = cards.map { |c| c["id"] }
      errors.add(:settings, "card IDs must be unique") if ids.uniq.size != ids.size
      errors.add(:settings, "each card must have an id and text") if cards.any? { |c| c["id"].blank? || c["text"].blank? }
    end
  end

  def energy_map_settings_valid
    return unless settings.present?

    periods = settings["time_periods"]
    scale_min = settings["scale_min"]
    scale_max = settings["scale_max"]

    errors.add(:settings, "must include time_periods array") if periods.blank?
    errors.add(:settings, "must have between 3 and 24 time periods") if periods && !periods.size.between?(3, 24)
    errors.add(:settings, "must include scale_min") if scale_min.blank?
    errors.add(:settings, "must include scale_max") if scale_max.blank?
    errors.add(:settings, "scale_min must be less than scale_max") if scale_min && scale_max && scale_min >= scale_max
  end

  def emoji_reaction_settings_valid
    return unless settings.present?

    options = settings["emoji_options"]
    errors.add(:settings, "must include emoji_options array") if options.blank?
    errors.add(:settings, "must have between 3 and 10 emoji options") if options && !options.size.between?(3, 10)

    if options.present?
      emojis = options.map { |o| o["emoji"] }
      errors.add(:settings, "emojis must be unique") if emojis.uniq.size != emojis.size
      errors.add(:settings, "each option must have an emoji and label") if options.any? { |o| o["emoji"].blank? || o["label"].blank? }
    end
  end

  def character_sheet_settings_valid
    return unless settings.present?

    total_points = settings["total_points"]
    stats = settings["stats"]

    errors.add(:settings, "must include total_points") if total_points.blank?
    errors.add(:settings, "total_points must be between 10 and 100") if total_points && !total_points.between?(10, 100)
    errors.add(:settings, "must include stats array") if stats.blank?
    errors.add(:settings, "must have between 3 and 10 stats") if stats && !stats.size.between?(3, 10)

    if stats.present?
      ids = stats.map { |s| s["id"] }
      errors.add(:settings, "stat IDs must be unique") if ids.uniq.size != ids.size
      errors.add(:settings, "each stat must have id, label, and description") if stats.any? { |s| s["id"].blank? || s["label"].blank? }

      max_sum = stats.sum { |s| s["max"] || 10 }
      errors.add(:settings, "total_points exceeds maximum possible allocation") if total_points && max_sum < total_points
    end
  end
end
