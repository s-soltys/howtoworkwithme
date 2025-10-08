class Profile < ApplicationRecord
  has_secure_token :unique_token, length: 36

  # Associations
  belongs_to :response
  has_one :employee, through: :response
  has_one :questionnaire, through: :response

  # Validations
  validates :unique_token, uniqueness: true
  validates :response_id, uniqueness: true
  validate :response_must_be_submitted

  # Scopes
  scope :most_viewed, -> { order(viewed_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Business logic
  def increment_view_count!
    increment!(:viewed_count)
  end

  private

  def response_must_be_submitted
    if response && !response.submitted?
      errors.add(:response, "must be submitted before creating a profile")
    end
  end
end
