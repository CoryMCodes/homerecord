class Entries::TimelineComponent < ApplicationComponent
  attr_reader :entries, :home

  def initialize(entries:, home:)
    @entries = entries
    @home = home
  end

  def groups
    entries.chunk { |entry| entry.occurred_on.strftime("%B %Y") }
  end
end
