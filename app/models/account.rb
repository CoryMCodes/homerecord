class Account < ApplicationRecord
  DEFAULT_NAME = "My household"

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :homes, dependent: :destroy

  validates :name, presence: true
end
