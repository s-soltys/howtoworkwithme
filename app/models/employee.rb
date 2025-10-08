class Employee < ApplicationRecord
  # Associations
  belongs_to :organization
  has_many :responses, dependent: :destroy
  has_many :profiles, through: :responses

  # Validations
  validates :name, presence: true
  validates :organization_id, presence: true
end
