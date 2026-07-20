require "application_system_test_case"

class HomeSearchTest < ApplicationSystemTestCase
  test "search panel opens closes on click-away and navigates to a result" do
    sign_in
    visit home_path(homes(:main))

    fill_in "q", with: "reliable"

    assert_selector "turbo-frame#home_search_results a", text: "Replaced water heater"

    find("h1", text: "Main Home").click

    assert_no_selector "turbo-frame#home_search_results a", text: "Replaced water heater"

    fill_in "q", with: "reliable"
    click_link "Replaced water heater"

    assert_current_path home_entry_path(homes(:main), entries(:water_heater_replacement))
    assert_selector "h1", text: "Replaced water heater"
  end

  private

  def sign_in
    Current.session = users(:owner).sessions.create!

    visit root_path

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      page.driver.browser.manage.add_cookie(name: "session_id", value: cookie_jar[:session_id])
    end
  end
end
