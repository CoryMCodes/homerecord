class Home < ApplicationRecord
  HOME_TYPES = %w[house condo apartment rental other].freeze

  belongs_to :account
  has_many :items, dependent: :destroy
  has_many :entries, dependent: :destroy

  before_validation :normalize_blank_home_type

  validates :name, presence: true
  validates :home_type, inclusion: { in: HOME_TYPES }, allow_nil: true

  private

  def normalize_blank_home_type
    self.home_type = nil if home_type.blank?
  end
end
