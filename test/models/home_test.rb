require "test_helper"

class HomeTest < ActiveSupport::TestCase
  test "requires a name" do
    home = Home.new(account: accounts(:household))

    assert_not home.valid?
    assert_includes home.errors[:name], "can't be blank"
  end

  test "allows blank home type" do
    home = Home.new(account: accounts(:household), name: "Lake House")

    assert home.valid?
  end

  test "normalizes blank home type to nil" do
    home = Home.new(account: accounts(:household), name: "Lake House", home_type: "")

    assert home.valid?
    assert_nil home.home_type
  end

  test "validates allowed home type" do
    home = Home.new(account: accounts(:household), name: "Lake House", home_type: "castle")

    assert_not home.valid?
    assert_includes home.errors[:home_type], "is not included in the list"
  end
end
