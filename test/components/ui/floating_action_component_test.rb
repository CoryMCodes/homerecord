require "test_helper"

class Ui::FloatingActionComponentTest < ViewComponent::TestCase
  test "renders an accessible fixed primary action" do
    render_inline Ui::FloatingActionComponent.new(href: "/homes/1/items/new", label: "Add item")

    assert_selector "a[href='/homes/1/items/new'][aria-label='Add item']"
    assert_selector "a .sr-only", text: "Add item"
    assert_selector "a", text: "+"
  end
end
