require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  test "shows items for a home" do
    sign_in_as users(:owner)

    get home_items_url(homes(:main))

    assert_response :success
    assert_select "h1", "Items for Main Home"
    assert_select "a[href='#{home_path(homes(:main))}']", "Back to timeline"
    assert_select "a[href='#{new_home_item_path(homes(:main))}']", "Add item"
    assert_select "li", text: /Water Heater/
    assert_select "li", text: /Other Water Heater/, count: 0
  end

  test "shows an empty state when a home has no items" do
    sign_in_as users(:owner)
    home = accounts(:household).homes.create!(name: "Empty Item Home")

    get home_items_url(home)

    assert_response :success
    assert_select "h1", "Items for Empty Item Home"
    assert_select "p", "No systems or appliances yet."
    assert_select "li", 0
  end

  test "blocks item index for a home outside the current account" do
    sign_in_as users(:owner)

    get home_items_url(homes(:other))

    assert_response :not_found
  end

  test "shows the new item form" do
    sign_in_as users(:owner)

    get new_home_item_url(homes(:main))

    assert_response :success
    assert_select "h1", "Add item"
    assert_select "form[action='#{home_items_path(homes(:main))}'][method='post']"
    assert_select "select[name='item[item_kind]']"
    assert_select "input[name='item[name]']"
    assert_select "input[name='item[brand]']"
    assert_select "input[name='item[model_number]']"
    assert_select "input[name='item[serial_number]']"
    assert_select "input[name='item[installed_on]'][type='date']"
    assert_select "textarea[name='item[notes]']"
    assert_select "input[name='item[home_id]']", 0
  end

  test "creates an item under the selected home" do
    sign_in_as users(:owner)

    assert_difference -> { Item.count }, 1 do
      post home_items_url(homes(:main)), params: {
        item: {
          item_kind: "system",
          name: "HVAC",
          brand: "Carrier",
          model_number: "HX-200",
          serial_number: "SN-200",
          installed_on: "2025-03-01",
          notes: "Attic air handler",
          home_id: homes(:other).id
        }
      }
    end

    item = Item.order(:created_at).last
    assert_equal homes(:main), item.home
    assert_equal "system", item.item_kind
    assert_equal "HVAC", item.name
    assert_equal "Carrier", item.brand
    assert_equal "HX-200", item.model_number
    assert_equal "SN-200", item.serial_number
    assert_equal Date.new(2025, 3, 1), item.installed_on
    assert_equal "Attic air handler", item.notes
    assert_redirected_to home_item_url(homes(:main), item)
  end

  test "does not create an invalid item" do
    sign_in_as users(:owner)

    assert_no_difference -> { Item.count } do
      post home_items_url(homes(:main)), params: {
        item: {
          item_kind: "appliance",
          name: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Add item"
    assert_select "[role='alert']", /Name can't be blank/
  end

  test "shows an item detail page" do
    sign_in_as users(:owner)
    item = items(:water_heater)

    get home_item_url(homes(:main), item)

    assert_response :success
    assert_select "h1", "Water Heater"
    assert_select "turbo-frame#item_#{item.id}"
    assert_select "a[href='#{edit_home_item_path(homes(:main), item)}']", "Edit"
    assert_select "p", /Rheem/
    assert_select "p", /WH-100/
    assert_select "p", /SN-100/
    assert_select "p", /Basement utility closet/
  end

  test "does not show an item from another home" do
    sign_in_as users(:owner)

    get home_item_url(homes(:main), items(:other_water_heater))

    assert_response :not_found
  end

  test "does not show an item when the nested home is outside the current account" do
    sign_in_as users(:owner)

    get home_item_url(homes(:other), items(:other_water_heater))

    assert_response :not_found
  end

  test "renders edit form inside the item turbo frame" do
    sign_in_as users(:owner)
    item = items(:water_heater)

    get edit_home_item_url(homes(:main), item), headers: { "Turbo-Frame" => "item_#{item.id}" }

    assert_response :success
    assert_select "turbo-frame#item_#{item.id}" do
      assert_select "form[action='#{home_item_path(homes(:main), item)}'][method='post']"
      assert_select "input[name='_method'][value='patch']"
      assert_select "select[name='item[item_kind]']"
      assert_select "input[name='item[name]'][value='Water Heater']"
      assert_select "input[name='item[brand]'][value='Rheem']"
      assert_select "textarea[name='item[notes]']", /Basement utility closet/
    end
  end

  test "updates an item and redirects with see other" do
    sign_in_as users(:owner)
    item = items(:water_heater)

    patch home_item_url(homes(:main), item), params: {
      item: {
        item_kind: "system",
        name: "Heat Pump",
        brand: "Trane",
        model_number: "TP-300",
        serial_number: "SN-300",
        installed_on: "2026-02-10",
        notes: "Outdoor unit"
      }
    }, headers: { "Turbo-Frame" => "item_#{item.id}" }

    assert_redirected_to home_item_url(homes(:main), item)
    assert_response :see_other

    item.reload
    assert_equal "system", item.item_kind
    assert_equal "Heat Pump", item.name
    assert_equal "Trane", item.brand
    assert_equal "TP-300", item.model_number
    assert_equal "SN-300", item.serial_number
    assert_equal Date.new(2026, 2, 10), item.installed_on
    assert_equal "Outdoor unit", item.notes

    follow_redirect!

    assert_response :success
    assert_select "turbo-frame#item_#{item.id}" do
      assert_select "h1", "Heat Pump"
      assert_select "p", /Trane/
      assert_select "p", /TP-300/
      assert_select "p", /SN-300/
      assert_select "p", /Outdoor unit/
    end
  end

  test "does not update an invalid item" do
    sign_in_as users(:owner)
    item = items(:water_heater)

    patch home_item_url(homes(:main), item), params: {
      item: {
        item_kind: "system",
        name: ""
      }
    }, headers: { "Turbo-Frame" => "item_#{item.id}" }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#item_#{item.id}" do
      assert_select "form[action='#{home_item_path(homes(:main), item)}'][method='post']"
      assert_select "[role='alert']", /Name can't be blank/
    end

    assert_equal "Water Heater", item.reload.name
  end
end
