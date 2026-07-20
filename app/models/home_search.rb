class HomeSearch
  MAX_QUERY_LENGTH = 80
  LIMIT_PER_GROUP = 5

  Result = Data.define(:query, :entries, :items, :attachment_matches) do
    def any?
      entries.any? || items.any? || attachment_matches.any?
    end
  end

  AttachmentMatch = Data.define(:entry, :filename)

  def initialize(home:, query:)
    @home = home
    @query = query.to_s.strip.first(MAX_QUERY_LENGTH)
  end

  def results
    return empty_results if query.blank?

    Result.new(
      query: query,
      entries: matching_entries,
      items: matching_items,
      attachment_matches: matching_attachment_matches
    )
  end

  private

  attr_reader :home, :query

  def empty_results
    Result.new(query: query, entries: Entry.none, items: Item.none, attachment_matches: [])
  end

  def matching_entries
    home.entries
      .where(
        "title ILIKE :pattern OR description ILIKE :pattern OR contractor_name ILIKE :pattern",
        pattern: like_pattern
      )
      .order(occurred_on: :desc, id: :desc)
      .limit(LIMIT_PER_GROUP)
  end

  def matching_items
    home.items
      .where(
        "name ILIKE :pattern OR brand ILIKE :pattern OR model_number ILIKE :pattern OR serial_number ILIKE :pattern",
        pattern: like_pattern
      )
      .order(:name, :id)
      .limit(LIMIT_PER_GROUP)
  end

  def matching_attachment_matches
    rows = home.entries
      .joins(attachments_attachments: :blob)
      .where("active_storage_blobs.filename ILIKE :pattern", pattern: like_pattern)
      .order(occurred_on: :desc, id: :desc)
      .order(Arel.sql("active_storage_blobs.filename ASC"))
      .limit(LIMIT_PER_GROUP)
      .pluck("entries.id", "active_storage_blobs.filename")

    entries_by_id = home.entries.where(id: rows.map(&:first)).index_by(&:id)

    rows.filter_map do |entry_id, filename|
      entry = entries_by_id[entry_id]
      AttachmentMatch.new(entry: entry, filename: filename) if entry.present?
    end
  end

  def like_pattern
    @like_pattern ||= "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
  end
end
