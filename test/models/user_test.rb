require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires email address" do
    user = User.new(password: "password", password_confirmation: "password")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email address" do
    user = User.new(email_address: users(:owner).email_address.upcase, password: "password", password_confirmation: "password")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "rolls back user creation when default account cannot be created" do
    original_create = Account.method(:create!)
    Account.define_singleton_method(:create!) do |*|
      account = Account.new
      account.errors.add(:name, "forced failure")
      raise ActiveRecord::RecordInvalid.new(account)
    end

    assert_no_difference -> { User.count } do
      assert_no_difference -> { Account.count } do
        assert_no_difference -> { Membership.count } do
          assert_raises(ActiveRecord::RecordInvalid) do
            User.create_with_default_account!(
              email_address: "rollback@example.com",
              password: "password",
              password_confirmation: "password"
            )
          end
        end
      end
    end
  ensure
    Account.define_singleton_method(:create!, original_create)
  end
end
