require "test_helper"

class Ui::SearchFieldComponentTest < ViewComponent::TestCase
  test "renders a semantic search form" do
    render_inline Ui::SearchFieldComponent.new(
      url: "/homes/1",
      value: "water heater",
      placeholder: "Find an appliance manual..."
    )

    assert_selector "form[role='search'][action='/homes/1'][method='get']"
    assert_selector "label .sr-only", text: "Search"
    assert_selector "input[type='search'][name='q'][value='water heater']"
    assert_selector "input[placeholder='Find an appliance manual...']"
  end
end
