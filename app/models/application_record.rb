class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Global Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    # Allow searching on all column names except sensitive fields
    column_names - ["encrypted_password", "password_digest", "reset_password_token"]
  end

  def self.ransackable_associations(auth_object = nil)
    # Allow searching on all associations
    reflect_on_all_associations.map(&:name).map(&:to_s)
  end
end
