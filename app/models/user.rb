class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :created_entries, class_name: "Entry", foreign_key: :created_by_user_id, inverse_of: :created_by_user, dependent: :restrict_with_exception

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
