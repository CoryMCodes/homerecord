require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials redirects to the homes landing route" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to homes_url
    assert cookies[:session_id]
  end

  test "create returns to a protected page requested before authentication" do
    get home_url(homes(:main))
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:owner).email_address, password: "password" }

    assert_redirected_to home_url(homes(:main))
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
