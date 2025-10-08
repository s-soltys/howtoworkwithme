class Category < ApplicationRecord
  # Associations
  belongs_to :questionnaire
  has_many :questions, -> { order(position: :asc) }, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :questionnaire_id }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :questionnaire_not_locked, on: [ :create, :update, :destroy ]

  private

  def questionnaire_not_locked
    if questionnaire&.locked?
      errors.add(:base, "Cannot modify category when questionnaire is locked")
    end
  end
end
