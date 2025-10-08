class Category < ApplicationRecord
  # Associations
  belongs_to :questionnaire
  has_many :questions, -> { order(position: :asc) }, dependent: :destroy

  # Callbacks
  before_validation :set_position, on: :create

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :questionnaire_id }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :questionnaire_not_locked, on: [ :create, :update, :destroy ]

  private

  def set_position
    return if position.present?
    self.position = (questionnaire.categories.maximum(:position) || 0) + 1
  end

  def questionnaire_not_locked
    if questionnaire&.locked?
      errors.add(:base, "Cannot modify category when questionnaire is locked")
    end
  end
end
