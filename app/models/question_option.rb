class QuestionOption < ApplicationRecord
  # Associations
  belongs_to :question
  has_many :answers, foreign_key: :selected_option_id, dependent: :nullify

  # Validations
  validates :text, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :questionnaire_not_locked, on: [ :create, :update, :destroy ]

  private

  def questionnaire_not_locked
    if question&.category&.questionnaire&.locked?
      errors.add(:base, "Cannot modify option when questionnaire is locked")
    end
  end
end
