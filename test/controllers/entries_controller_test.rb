require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  test "shows the new entry form" do
    sign_in_as users(:owner)

    get new_home_entry_url(homes(:main))

    assert_response :success
    assert_select "h1", "Add entry"
    assert_select "form[action='#{home_entries_path(homes(:main))}'][method='post']"
    assert_select "select[name='entry[entry_type]']"
    assert_select "input[name='entry[title]']"
    assert_select "input[name='entry[occurred_on]'][type='date']"
    assert_select "textarea[name='entry[description]']"
    assert_select "input[name='entry[cost]']"
    assert_select "input[name='entry[contractor_name]']"
    assert_select "select[name='entry[item_id]']"
    assert_select "option[value='#{items(:water_heater).id}']", "Water Heater"
    assert_select "option[value='#{items(:other_water_heater).id}']", 0
    assert_select "input[name='entry[home_id]']", 0
    assert_select "input[name='entry[created_by_user_id]']", 0
    assert_select "input[name='entry[cost_cents]']", 0
  end

  test "blocks new entry form for a home outside the current account" do
    sign_in_as users(:owner)

    get new_home_entry_url(homes(:other))

    assert_response :not_found
  end

  test "creates an entry under the selected home and redirects to details" do
    sign_in_as users(:owner)

    assert_difference -> { Entry.count }, 1 do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          item_id: items(:water_heater).id,
          description: "Replaced shutoff valve.",
          cost: "125.50",
          contractor_name: "Reliable Plumbing",
          home_id: homes(:other).id,
          created_by_user_id: users(:other_owner).id,
          cost_cents: 1
        }
      }
    end

    entry = Entry.order(:created_at).last
    assert_equal homes(:main), entry.home
    assert_equal users(:owner), entry.created_by_user
    assert_equal items(:water_heater), entry.item
    assert_equal "repair", entry.entry_type
    assert_equal "Fixed sink leak", entry.title
    assert_equal Date.new(2026, 7, 10), entry.occurred_on
    assert_equal "Replaced shutoff valve.", entry.description
    assert_equal 12_550, entry.cost_cents
    assert_equal "Reliable Plumbing", entry.contractor_name
    assert_redirected_to home_entry_url(homes(:main), entry)
  end

  test "creates an entry without an item or cost" do
    sign_in_as users(:owner)

    assert_difference -> { Entry.count }, 1 do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "memory",
          title: "Hosted dinner",
          occurred_on: "2026-07-11",
          item_id: "",
          cost: ""
        }
      }
    end

    entry = Entry.order(:created_at).last
    assert_equal homes(:main), entry.home
    assert_nil entry.item
    assert_nil entry.cost_cents
    assert_redirected_to home_entry_url(homes(:main), entry)
  end

  test "does not create an invalid entry" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "",
          occurred_on: "2026-07-10"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Add entry"
    assert_select "[role='alert']", /Title can't be blank/
  end

  test "does not create an entry with invalid cost" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "twelve dollars"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='twelve dollars']"
  end

  test "does not create an entry with negative cost" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "-12.00"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='-12.00']"
  end

  test "does not create an entry with an item from another home" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          item_id: items(:other_water_heater).id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Item must belong to this home/
  end
end
