require "test_helper"

class AuthenticationMenuTest < ActionDispatch::IntegrationTest
  test "signed out visitors can open the account menu and sign in" do
    get root_url

    assert_response :success
    assert_select "header nav[aria-label='Account'] details" do
      assert_select "summary[aria-label='Open account menu']", "Menu"
      assert_select "a[href='#{new_session_path}']", "Sign in"
      assert_select "form[action='#{session_path}']", count: 0
    end
  end

  test "signed in users can open the account menu and sign out" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "header nav[aria-label='Account'] details" do
      assert_select "summary[aria-label='Open account menu']", "Menu"
      assert_select "a[href='#{new_session_path}']", count: 0
      assert_select "form[action='#{session_path}'][method='post']" do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button[type='submit']", "Sign out"
      end
    end
  end
end
