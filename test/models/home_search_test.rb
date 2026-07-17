require "test_helper"

class HomeSearchTest < ActiveSupport::TestCase
  test "blank query returns empty results" do
    results = HomeSearch.new(home: homes(:main), query: "   ").results

    assert_equal "", results.query
    assert_not results.any?
    assert_empty results.entries
    assert_empty results.items
    assert_empty results.attachment_matches
  end

  test "matches entries by title description and contractor name" do
    home = homes(:main)

    title_results = HomeSearch.new(home: home, query: "replaced").results
    description_results = HomeSearch.new(home: home, query: "failing tank").results
    contractor_results = HomeSearch.new(home: home, query: "reliable").results

    assert_includes title_results.entries, entries(:water_heater_replacement)
    assert_includes description_results.entries, entries(:water_heater_replacement)
    assert_includes contractor_results.entries, entries(:water_heater_replacement)
  end

  test "matches items by name brand model number and serial number" do
    home = homes(:main)

    name_results = HomeSearch.new(home: home, query: "water heater").results
    brand_results = HomeSearch.new(home: home, query: "rheem").results
    model_results = HomeSearch.new(home: home, query: "wh-100").results
    serial_results = HomeSearch.new(home: home, query: "sn-100").results

    assert_includes name_results.items, items(:water_heater)
    assert_includes brand_results.items, items(:water_heater)
    assert_includes model_results.items, items(:water_heater)
    assert_includes serial_results.items, items(:water_heater)
  end

  test "matches attachment filenames and returns the owning entry" do
    entry = entries(:water_heater_replacement)
    entry.attachments.attach(
      io: File.open(Rails.root.join("test/fixtures/files/warranty.pdf")),
      filename: "water-heater-warranty.pdf",
      content_type: "application/pdf"
    )

    results = HomeSearch.new(home: homes(:main), query: "warranty").results

    match = results.attachment_matches.find { |attachment_match| attachment_match.filename == "water-heater-warranty.pdf" }
    assert_not_nil match
    assert_equal entry, match.entry
  end

  test "does not return records from another home" do
    results = HomeSearch.new(home: homes(:main), query: "other").results

    assert_not_includes results.items, items(:other_water_heater)
    assert_empty results.entries
  end

  test "treats sql wildcard characters as plain text" do
    results = HomeSearch.new(home: homes(:main), query: "%").results

    assert_not results.any?
  end

  test "limits query length before matching" do
    long_name = "x" * HomeSearch::MAX_QUERY_LENGTH
    item = homes(:main).items.create!(item_kind: "system", name: long_name)

    results = HomeSearch.new(home: homes(:main), query: "#{long_name}trailing text").results

    assert_includes results.items, item
    assert_equal long_name, results.query
  end
end
