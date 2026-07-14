require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "requires a name" do
    item = Item.new(home: homes(:main), item_kind: "appliance")

    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end

  test "validates allowed item kind" do
    item = Item.new(home: homes(:main), name: "Kitchen Paint", item_kind: "finish")

    assert_not item.valid?
    assert_includes item.errors[:item_kind], "is not included in the list"
  end

  test "does not move homes when entries reference it" do
    item = items(:water_heater)

    assert_not item.update(home: homes(:other))
    assert_includes item.errors[:home], "cannot change while entries reference this item"
  end
end
