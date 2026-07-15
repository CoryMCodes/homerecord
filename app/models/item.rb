class Item < ApplicationRecord
  ITEM_KINDS = %w[appliance system].freeze

  belongs_to :home
  has_many :entries, dependent: :nullify

  validates :name, presence: true
  validates :item_kind, inclusion: { in: ITEM_KINDS }
  validate :home_unchanged_when_entries_exist, if: :will_save_change_to_home_id?

  private

  def home_unchanged_when_entries_exist
    errors.add(:home, "cannot change while entries reference this item") if entries.exists?
  end
end
