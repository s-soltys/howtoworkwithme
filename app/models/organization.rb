class Organization < ApplicationRecord
  has_secure_token :unique_token, length: 36

  # Associations
  has_many :questionnaires, dependent: :destroy
  has_many :employees, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :unique_token, uniqueness: true
end
