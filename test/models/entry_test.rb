require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "requires title" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
  end

  test "requires occurred on" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", title: "Replaced water heater")

    assert_not entry.valid?
    assert_includes entry.errors[:occurred_on], "can't be blank"
  end

  test "validates allowed entry type" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "reminder", title: "Change filter", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:entry_type], "is not included in the list"
  end

  test "allows blank item" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "memory", title: "Moved in", occurred_on: Date.current)

    assert entry.valid?
  end

  test "rejects item from another home" do
    entry = Entry.new(
      home: homes(:main),
      item: items(:other_water_heater),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )

    assert_not entry.valid?
    assert_includes entry.errors[:item], "must belong to the same home"
  end

  test "rejects negative cost" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "repair",
      title: "Garage door repair",
      occurred_on: Date.current,
      cost_cents: -1
    )

    assert_not entry.valid?
    assert_includes entry.errors[:cost_cents], "must be greater than or equal to 0"
  end
end
