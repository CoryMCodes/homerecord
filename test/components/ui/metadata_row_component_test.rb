require "test_helper"

class Ui::MetadataRowComponentTest < ViewComponent::TestCase
  test "renders nonblank metadata values" do
    render_inline Ui::MetadataRowComponent.new(items: [
      { label: "Item", value: "Water Heater" },
      { label: "Cost", value: "" },
      { label: "Contractor", value: nil }
    ])

    assert_selector "dl"
    assert_text "Item"
    assert_text "Water Heater"
    refute_text "Cost"
    refute_text "Contractor"
  end

  test "renders nothing when all values are blank" do
    render_inline Ui::MetadataRowComponent.new(items: [
      { label: "Item", value: nil }
    ])

    assert_no_selector "dl"
  end
end
