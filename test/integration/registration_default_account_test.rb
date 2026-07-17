require "test_helper"

class RegistrationDefaultAccountTest < ActionDispatch::IntegrationTest
  test "signup page links existing users to sign in" do
    get root_url

    assert_response :success
    assert_select "a[href=?]", new_session_path, text: "Sign in to your account"
  end

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

  test "signup rejects blank email without creating account records" do
    assert_no_difference -> { User.count } do
      assert_no_difference -> { Account.count } do
        assert_no_difference -> { Membership.count } do
          post registration_url, params: {
            user: {
              email_address: "",
              password: "password",
              password_confirmation: "password"
            }
          }
        end
      end
    end

    assert_response :unprocessable_entity
  end

  test "signup rejects duplicate email without creating account records" do
    assert_no_difference -> { User.count } do
      assert_no_difference -> { Account.count } do
        assert_no_difference -> { Membership.count } do
          post registration_url, params: {
            user: {
              email_address: users(:owner).email_address.upcase,
              password: "password",
              password_confirmation: "password"
            }
          }
        end
      end
    end

    assert_response :unprocessable_entity
  end
end
