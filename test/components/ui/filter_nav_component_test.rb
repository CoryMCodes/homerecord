require "test_helper"

class Ui::FilterNavComponentTest < ViewComponent::TestCase
  test "renders active and inactive filter links" do
    items = [
      { label: "All", href: "/homes/1", active: true },
      { label: "Maintenance", href: "/homes/1?category=maintenance", active: false }
    ]

    render_inline Ui::FilterNavComponent.new(label: "Timeline filters", items: items)

    assert_selector "nav[aria-label='Timeline filters']"
    assert_selector "a[aria-current='page']", text: "All"
    assert_selector "a[href='/homes/1?category=maintenance']", text: "Maintenance"
    assert_selector "a[aria-current='page']", count: 1
  end
end
