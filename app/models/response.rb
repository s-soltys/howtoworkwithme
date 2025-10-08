class Response < ApplicationRecord
  has_secure_token :unique_token, length: 36

  # Enums
  enum :status, { draft: "draft", submitted: "submitted" }

  # Associations
  belongs_to :questionnaire
  belongs_to :employee, optional: true
  has_many :answers, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Validations
  validates :unique_token, uniqueness: true
  validates :status, presence: true
  validates :submitted_at, presence: true, if: -> { submitted? }

  # Nested attributes
  accepts_nested_attributes_for :answers

  # Scopes
  scope :most_recent_first, -> { order(submitted_at: :desc) }
  scope :for_employee, ->(employee) { where(employee: employee) }
  scope :for_questionnaire, ->(questionnaire) { where(questionnaire: questionnaire) }

  # Business logic
  def submit!
    update!(status: :submitted, submitted_at: Time.current)
  end
end
