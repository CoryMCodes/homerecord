require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects to the current home's timeline" do
    sign_in_as users(:owner)

    get homes_url

    assert_redirected_to home_url(homes(:main))
  end

  test "index redirects to home creation when the account has no home" do
    user = User.create_with_default_account!(
      email_address: "homeless@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in_as user

    get homes_url

    assert_redirected_to new_home_url
  end

  test "new redirects to the timeline when the account already has a home" do
    sign_in_as users(:owner)

    get new_home_url

    assert_redirected_to home_url(homes(:main))
  end

  test "shows a home in the current account" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h1", "Main Home"
    assert_select "a[href='#{home_path(homes(:main))}']", "Timeline"
    assert_select "a[href='#{homes_path}']", count: 0
  end

  test "does not show a home from another account" do
    sign_in_as users(:owner)

    get home_url(homes(:other))

    assert_response :not_found
  end

  test "shows the new home form" do
    user = User.create_with_default_account!(
      email_address: "new-home-form@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in_as user

    get new_home_url

    assert_response :success
    assert_select "h1", "Add a home"
    assert_select "form[action='#{homes_path}'][method='post']"
    assert_select "input[name='home[name]']"
    assert_select "textarea[name='home[address]']"
    assert_select "select[name='home[home_type]']"
  end

  test "creates a home in the current account and redirects to its timeline" do
    user = User.create_with_default_account!(
      email_address: "first-home@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in_as user

    assert_difference -> { Home.count }, 1 do
      post homes_url, params: {
        home: {
          name: "Lake House",
          address: "9 Lake Road",
          home_type: "house",
          account_id: accounts(:other_household).id
        }
      }
    end

    home = Home.order(:created_at).last
    assert_equal user.accounts.first, home.account
    assert_equal "Lake House", home.name
    assert_equal "9 Lake Road", home.address
    assert_equal "house", home.home_type
    assert_redirected_to home_url(home)

    follow_redirect!

    assert_response :success
    assert_select "h1", "Lake House"
  end

  test "does not create an invalid home" do
    user = User.create_with_default_account!(
      email_address: "invalid-home@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in_as user

    assert_no_difference -> { Home.count } do
      post homes_url, params: {
        home: {
          name: "",
          address: "9 Lake Road",
          home_type: "house"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Add a home"
    assert_select "[role='alert']", /Name can't be blank/
  end

  test "does not create a second home" do
    sign_in_as users(:owner)

    assert_no_difference -> { Home.count } do
      post homes_url, params: {
        home: { name: "Lake House", address: "9 Lake Road", home_type: "house" }
      }
    end

    assert_redirected_to home_url(homes(:main))
  end

  test "shows timeline entries newest first" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "ol li", 2

    timeline_titles = css_select("ol li h3").map { |title| title.text.strip }
    assert_equal [ "Replaced water heater", "Moved in" ], timeline_titles
  end

  test "filters timeline entries by entry type" do
    sign_in_as users(:owner)
    replacement_filter_path = home_path(homes(:main), entry_type: "replacement")

    get home_url(homes(:main), entry_type: "replacement")

    assert_response :success
    assert_select "nav[aria-label='Timeline filters'] a[aria-current='page']", "Replacement"
    replacement_link = css_select("nav[aria-label='Timeline filters'] a").find { |link| link.text.strip == "Replacement" }
    assert_equal replacement_filter_path, replacement_link["href"]
    assert_select "ol li", 1
    assert_select "ol li h3", "Replaced water heater"
    assert_select "ol li h3", { text: "Moved in", count: 0 }
  end

  test "ignores unsupported timeline entry type filters" do
    sign_in_as users(:owner)

    get home_url(homes(:main), entry_type: "reminder")

    assert_response :success
    assert_select "nav[aria-label='Timeline filters'] a[aria-current='page']", "All"
    timeline_titles = css_select("ol li h3").map { |title| title.text.strip }
    assert_equal [ "Replaced water heater", "Moved in" ], timeline_titles
  end

  test "orders timeline entries with a stable newest id tie breaker" do
    sign_in_as users(:owner)
    home = accounts(:household).homes.create!(name: "Same Day Home")
    older_entry = home.entries.create!(
      entry_type: "note",
      title: "Earlier same day note",
      occurred_on: Date.new(2025, 1, 1),
      created_by_user: users(:owner)
    )
    newer_entry = home.entries.create!(
      entry_type: "note",
      title: "Later same day note",
      occurred_on: older_entry.occurred_on,
      created_by_user: users(:owner)
    )

    get home_url(home)

    assert_response :success
    timeline_titles = css_select("ol li h3").map { |title| title.text.strip }
    assert_equal [ newer_entry.title, older_entry.title ], timeline_titles
  end

  test "shows an empty timeline state when the home has no entries" do
    sign_in_as users(:owner)
    home = accounts(:household).homes.create!(name: "Empty Home")

    get home_url(home)

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "section h2", "No timeline entries yet."
    assert_select "ol li", 0
  end

  test "timeline renders search and filter controls" do
    sign_in_as users(:owner)
    replacement_filter_path = home_path(homes(:main), entry_type: "replacement")

    get home_url(homes(:main))

    assert_response :success
    assert_select "form[role='search'][action='#{home_search_path(homes(:main))}'][data-turbo-frame='home_search_results']"
    assert_select "input[type='search'][name='q']"
    assert_select "turbo-frame#home_search_results"
    assert_select "nav[aria-label='Timeline filters']"
    assert_select "nav[aria-label='Timeline filters'] a[aria-current='page']", "All"
    replacement_link = css_select("nav[aria-label='Timeline filters'] a").find { |link| link.text.strip == "Replacement" }
    assert_equal replacement_filter_path, replacement_link["href"]
  end

  test "timeline links to home scoped items" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "a[href='#{home_items_path(homes(:main))}']", "View items"
    assert_select "a[href='#{new_home_item_path(homes(:main))}']", "Add item"
  end

  test "timeline links to new entry form" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "a[href='#{new_home_entry_path(homes(:main))}']", "Add entry"
  end

  test "timeline entry titles link to entry detail pages" do
    sign_in_as users(:owner)
    entry = entries(:water_heater_replacement)

    get home_url(homes(:main))

    assert_response :success
    assert_select "a[href='#{home_entry_path(homes(:main), entry)}']", "Replaced water heater"
  end
end
