class Questionnaire < ApplicationRecord
  has_secure_token :unique_token, length: 36

  # Associations
  belongs_to :organization
  has_many :categories, -> { order(position: :asc) }, dependent: :destroy
  has_many :questions, through: :categories
  has_many :responses, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :unique_token, uniqueness: true
  validates :organization_id, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :unlocked, -> { where(locked_at: nil) }

  # Business logic
  def locked?
    locked_at.present?
  end

  def lock!
    update!(locked_at: Time.current) unless locked?
  end
end
