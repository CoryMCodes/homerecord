class Entries::TimelineEntryComponent < ApplicationComponent
  attr_reader :entry

  def initialize(entry:)
    @entry = entry
  end

  def category_label
    entry.entry_type.humanize
  end

  def short_date
    entry.occurred_on.strftime("%b %-d")
  end

  def metadata_items
    [
      { label: "Item", value: entry.item&.name },
      { label: "Contractor", value: entry.contractor_name },
      { label: "Cost", value: cost_label }
    ]
  end

  private

  def cost_label
    return if entry.cost_cents.blank?

    number_to_currency(entry.cost_cents / 100.0, precision: 0)
  end
end
