require "test_helper"

class RegistrationDefaultAccountTest < ActionDispatch::IntegrationTest
  test "signup creates default account and owner membership" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Account.count }, 1 do
        assert_difference -> { Membership.count }, 1 do
          post registration_url, params: {
            user: {
              email_address: "new@example.com",
              password: "password",
              password_confirmation: "password"
            }
          }
        end
      end
    end

    user = User.find_by!(email_address: "new@example.com")

    assert_redirected_to homes_url
    assert_equal [ "My household" ], user.accounts.pluck(:name)
    assert_equal [ "owner" ], user.memberships.pluck(:role)
  end
end
