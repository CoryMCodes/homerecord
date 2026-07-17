class Entry < ApplicationRecord
  ENTRY_TYPES = %w[maintenance repair installation replacement inspection purchase note memory].freeze
  MAX_COST_CENTS = 2_147_483_647
  MAX_ATTACHMENTS = 10
  MAX_ATTACHMENT_SIZE = 20.megabytes
  ALLOWED_ATTACHMENT_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/heic
    image/heif
    application/pdf
  ].freeze
  ALLOWED_ATTACHMENT_EXTENSIONS = %w[jpg jpeg png heic heif pdf].freeze

  belongs_to :home
  belongs_to :item, optional: true
  belongs_to :created_by_user, class_name: "User", inverse_of: :created_entries
  has_many_attached :attachments

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :title, presence: true
  validates :occurred_on, presence: true
  validates :cost_cents, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_COST_CENTS }, allow_nil: true
  validate :item_belongs_to_home
  validate :acceptable_attachments

  private

  def item_belongs_to_home
    return if item.blank? || home.blank?

    errors.add(:item, "must belong to the same home") if item.home != home
  end

  def acceptable_attachments
    return unless attachments.attached?

    errors.add(:attachments, "can include at most #{MAX_ATTACHMENTS} files") if attachments.count > MAX_ATTACHMENTS

    attachments.each do |attachment|
      validate_attachment_content_type(attachment)
      validate_attachment_extension(attachment)
      validate_attachment_size(attachment)
    end
  end

  def validate_attachment_content_type(attachment)
    return if ALLOWED_ATTACHMENT_CONTENT_TYPES.include?(attachment.blob.content_type)

    errors.add(:attachments, "must be a JPEG, PNG, HEIC, HEIF, or PDF")
  end

  def validate_attachment_extension(attachment)
    extension = attachment.filename.extension_without_delimiter.to_s.downcase
    return if ALLOWED_ATTACHMENT_EXTENSIONS.include?(extension)

    errors.add(:attachments, "must use a .jpg, .jpeg, .png, .heic, .heif, or .pdf extension")
  end

  def validate_attachment_size(attachment)
    return if attachment.blob.byte_size <= MAX_ATTACHMENT_SIZE

    errors.add(:attachments, "must be 20 MB or smaller")
  end
end
