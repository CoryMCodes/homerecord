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
end
