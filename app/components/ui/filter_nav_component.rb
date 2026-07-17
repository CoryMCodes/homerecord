class Ui::FilterNavComponent < ApplicationComponent
  attr_reader :label, :items

  def initialize(label:, items:)
    @label = label
    @items = items
  end

  def item_classes(item)
    base = "shrink-0 rounded-full px-3 py-1 text-sm font-medium transition-all duration-200 motion-reduce:transition-none"

    if item[:active]
      "#{base} bg-card text-foreground shadow-card ring-1 ring-border"
    else
      "#{base} text-muted-foreground hover:text-foreground hover:bg-primary-soft"
    end
  end
end
