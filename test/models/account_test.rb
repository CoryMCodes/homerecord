require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "requires a name" do
    account = Account.new

    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "has users through memberships" do
    assert_includes accounts(:household).users, users(:owner)
  end
end
