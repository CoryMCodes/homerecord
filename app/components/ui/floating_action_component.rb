class Ui::FloatingActionComponent < ApplicationComponent
  attr_reader :href, :label, :symbol

  def initialize(href:, label:, symbol: "+")
    @href = href
    @label = label
    @symbol = symbol
  end
end
