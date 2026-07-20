require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  test "renders search results in the home search turbo frame" do
    sign_in_as users(:owner)

    get home_search_url(homes(:main), q: "reliable")

    assert_response :success
    assert_select "turbo-frame#home_search_results"
    assert_select "a[href='#{home_entry_path(homes(:main), entries(:water_heater_replacement))}']", /Replaced water heater/
  end

  test "renders item result links" do
    sign_in_as users(:owner)

    get home_search_url(homes(:main), q: "rheem")

    assert_response :success
    assert_select "h2", "Items"
    assert_select "a[href='#{home_item_path(homes(:main), items(:water_heater))}']", /Water Heater/
  end

  test "renders attachment filename result links to owning entries" do
    sign_in_as users(:owner)
    entry = entries(:water_heater_replacement)
    entry.attachments.attach(
      io: File.open(Rails.root.join("test/fixtures/files/warranty.pdf")),
      filename: "water-heater-warranty.pdf",
      content_type: "application/pdf"
    )

    get home_search_url(homes(:main), q: "warranty")

    assert_response :success
    assert_select "h2", "Attachments"
    assert_select "a[href='#{home_entry_path(homes(:main), entry)}']", /water-heater-warranty.pdf/
  end

  test "renders no result state for unmatched queries" do
    sign_in_as users(:owner)

    get home_search_url(homes(:main), q: "does-not-exist")

    assert_response :success
    assert_select "turbo-frame#home_search_results"
    assert_select "p", "No results found."
  end

  test "blank query returns an empty frame" do
    sign_in_as users(:owner)

    get home_search_url(homes(:main), q: " ")

    assert_response :success
    assert_select "turbo-frame#home_search_results"
    assert_select "a", 0
    assert_select "p", { text: "No results found.", count: 0 }
  end

  test "does not render search for a home outside the current account" do
    sign_in_as users(:owner)

    get home_search_url(homes(:other), q: "water")

    assert_response :not_found
  end
end
