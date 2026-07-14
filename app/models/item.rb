class Item < ApplicationRecord
  ITEM_KINDS = %w[appliance system].freeze

  belongs_to :home
  has_many :entries, dependent: :nullify

  validates :name, presence: true
  validates :item_kind, inclusion: { in: ITEM_KINDS }
end
