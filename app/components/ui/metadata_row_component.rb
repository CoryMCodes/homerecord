class Ui::MetadataRowComponent < ApplicationComponent
  def initialize(items:)
    @items = items.filter_map do |item|
      value = item[:value]
      next if value.blank?

      { label: item[:label], value: value }
    end
  end

  def render?
    @items.any?
  end

  attr_reader :items
end
