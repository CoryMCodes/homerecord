class Entry < ApplicationRecord
  ENTRY_TYPES = %w[maintenance repair installation replacement inspection purchase note memory].freeze

  belongs_to :home
  belongs_to :item, optional: true
  belongs_to :created_by_user, class_name: "User", inverse_of: :created_entries

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :title, presence: true
  validates :occurred_on, presence: true
  validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :item_belongs_to_home

  private

  def item_belongs_to_home
    return if item.blank? || home.blank?

    errors.add(:item, "must belong to the same home") if item.home_id != home_id
  end
end
