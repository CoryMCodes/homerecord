require "test_helper"

class Entries::TimelineEntryComponentTest < ViewComponent::TestCase
  test "renders timeline entry title date description and item metadata" do
    entry = entries(:water_heater_replacement)

    render_inline Entries::TimelineEntryComponent.new(entry: entry)

    assert_selector "li"
    assert_selector "h3", text: entry.title
    assert_selector "time[datetime='#{entry.occurred_on.iso8601}']", text: entry.occurred_on.strftime("%b %-d")
    assert_text entry.description
    assert_text entry.entry_type.humanize
    assert_text entry.item.name
  end

  test "omits optional description and item metadata when absent" do
    entry = entries(:move_in)

    render_inline Entries::TimelineEntryComponent.new(entry: entry)

    assert_selector "h3", text: entry.title
    assert_no_selector "p.mt-1"
    assert_no_text "Water Heater"
  end
end
