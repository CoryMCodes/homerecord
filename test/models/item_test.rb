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
end
