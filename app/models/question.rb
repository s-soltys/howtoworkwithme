class Question < ApplicationRecord
  # Enums
  enum :question_type, { text: "text", single_choice: "single_choice", multiple_choice: "multiple_choice", yes_no: "yes_no" }

  # Associations
  belongs_to :category
  has_many :question_options, -> { order(position: :asc) }, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_one :questionnaire, through: :category

  # Validations
  validates :text, presence: true
  validates :question_type, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :choice_questions_need_options, if: :persisted?
  validate :questionnaire_not_locked, on: [ :create, :update, :destroy ]

  # Nested attributes
  accepts_nested_attributes_for :question_options, allow_destroy: true, reject_if: proc { |attrs| attrs[:text].blank? }

  private

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
end
