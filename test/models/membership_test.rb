require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "requires an allowed role" do
    membership = Membership.new(user: users(:owner), account: accounts(:other_household), role: "admin")

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "enforces unique user account pairs" do
    duplicate = Membership.new(user: users(:owner), account: accounts(:household), role: Membership::OWNER_ROLE)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
