require "test_helper"

class Ui::ButtonComponentTest < ViewComponent::TestCase
  test "renders a primary link with semantic classes" do
    render_inline Ui::ButtonComponent.new(href: "/homes", variant: :primary) do
      "Open home"
    end

    assert_selector "a[href='/homes']", text: "Open home"
    assert_selector "a.bg-primary.text-primary-foreground"
  end

  test "renders a secondary button with the requested type" do
    render_inline Ui::ButtonComponent.new(variant: :secondary, type: "submit") do
      "Save"
    end

    assert_selector "button[type='submit']", text: "Save"
    assert_selector "button.bg-card.text-foreground"
  end

  test "marks disabled links as aria disabled" do
    render_inline Ui::ButtonComponent.new(href: "/homes", disabled: true) do
      "Unavailable"
    end

    assert_selector "a[aria-disabled='true']", text: "Unavailable"
  end

  test "rejects unknown variants" do
    assert_raises(ArgumentError) do
      render_inline Ui::ButtonComponent.new(variant: :loud) { "Nope" }
    end
  end
end
