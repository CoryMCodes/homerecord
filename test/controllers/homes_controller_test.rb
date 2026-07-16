require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  test "shows a home in the current account" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h1", "Main Home"
  end

  test "does not show a home from another account" do
    sign_in_as users(:owner)

    get home_url(homes(:other))

    assert_response :not_found
  end

  test "shows the new home form" do
    sign_in_as users(:owner)

    get new_home_url

    assert_response :success
    assert_select "h1", "Add a home"
    assert_select "form[action='#{homes_path}'][method='post']"
    assert_select "input[name='home[name]']"
    assert_select "textarea[name='home[address]']"
    assert_select "select[name='home[home_type]']"
  end

  test "creates a home in the current account and redirects to its timeline" do
    sign_in_as users(:owner)

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
    assert_equal accounts(:household), home.account
    assert_equal "Lake House", home.name
    assert_equal "9 Lake Road", home.address
    assert_equal "house", home.home_type
    assert_redirected_to home_url(home)

    follow_redirect!

    assert_response :success
    assert_select "h1", "Lake House"
  end

  test "does not create an invalid home" do
    sign_in_as users(:owner)

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

  test "shows timeline entries newest first" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "ol li", 2

    timeline_titles = css_select("ol li h3").map(&:text)
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
    timeline_titles = css_select("ol li h3").map(&:text)
    assert_equal [ newer_entry.title, older_entry.title ], timeline_titles
  end

  test "shows an empty timeline state when the home has no entries" do
    sign_in_as users(:owner)
    home = accounts(:household).homes.create!(name: "Empty Home")

    get home_url(home)

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "p", "No timeline entries yet."
    assert_select "ol li", 0
  end

  test "timeline links to home scoped items" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "a[href='#{home_items_path(homes(:main))}']", "View items"
    assert_select "a[href='#{new_home_item_path(homes(:main))}']", "Add item"
  end
end
