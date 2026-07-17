require "test_helper"

class Entries::TimelineComponentTest < ViewComponent::TestCase
  test "renders entries in the input order" do
    ordered_entries = [
      entries(:move_in),
      entries(:water_heater_replacement)
    ]

    render_inline Entries::TimelineComponent.new(entries: ordered_entries, home: homes(:main))

    titles = page.all("li h3").map { |title| title.text.strip }
    assert_equal ordered_entries.map(&:title), titles
  end

  test "groups entries by month without reordering them" do
    ordered_entries = [
      entries(:water_heater_replacement),
      entries(:move_in)
    ]

    render_inline Entries::TimelineComponent.new(entries: ordered_entries, home: homes(:main))

    assert_selector "h3", text: "January 2024"
    assert_selector "h3", text: "September 2023"
    headings = page.all("section[aria-label] > h3").map { |heading| heading.text.strip }
    assert_equal [ "January 2024", "September 2023" ], headings
  end

  test "renders empty state when no entries exist" do
    render_inline Entries::TimelineComponent.new(entries: [], home: homes(:main))

    assert_text "No timeline entries yet."
    assert_no_selector "ol li"
  end
end
