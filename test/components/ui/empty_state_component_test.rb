require "test_helper"

class Ui::EmptyStateComponentTest < ViewComponent::TestCase
  test "renders title body and optional action content" do
    render_inline Ui::EmptyStateComponent.new(
      title: "No timeline entries yet.",
      body: "Add the first thing that happened to this home."
    ) do
      %(<a href="/entries/new">Add entry</a>).html_safe
    end

    assert_selector "section", text: "No timeline entries yet."
    assert_text "Add the first thing that happened to this home."
    assert_selector "a[href='/entries/new']", text: "Add entry"
  end

  test "omits body when it is blank" do
    render_inline Ui::EmptyStateComponent.new(title: "Nothing here")

    assert_selector "section", text: "Nothing here"
    assert_no_selector "section p"
  end
end
