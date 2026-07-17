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
    assert_select "input[name='entry[attachments][]'][type='file'][multiple='multiple']"
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

  test "creates an entry with attached files" do
    sign_in_as users(:owner)

    assert_difference -> { Entry.count }, 1 do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "replacement",
          title: "Replaced water heater",
          occurred_on: "2026-07-10",
          attachments: [
            fixture_file_upload("install-photo.jpg", "image/jpeg"),
            fixture_file_upload("warranty.pdf", "application/pdf")
          ]
        }
      }
    end

    entry = Entry.order(:created_at).last
    assert_equal 2, entry.attachments.count
    assert_equal [ "install-photo.jpg", "warranty.pdf" ], entry.attachments.map { |attachment| attachment.filename.to_s }
    assert_redirected_to home_entry_url(homes(:main), entry)
  end

  test "does not create an entry with an unsupported attachment type" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "note",
          title: "Saved a note file",
          occurred_on: "2026-07-10",
          attachments: [
            fixture_file_upload("notes.txt", "text/plain")
          ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Attachments must be a JPEG, PNG, HEIC, HEIF, or PDF/
  end

  test "does not create an entry with more than ten attachments" do
    sign_in_as users(:owner)
    uploads = 11.times.map { |index| fixture_file_upload("warranty.pdf", "application/pdf", original_filename: "warranty-#{index}.pdf") }

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "note",
          title: "Saved warranty files",
          occurred_on: "2026-07-10",
          attachments: uploads
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Attachments can include at most 10 files/
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

  test "does not create an entry with a cost above the database integer limit" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "21474836.48"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='21474836.48']"
  end

  test "does not create an entry with an extreme exponent cost" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "1e1000000000"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='1e1000000000']"
  end

  test "does not create an entry with NaN cost" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "NaN"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='NaN']"
  end

  test "does not create an entry with Infinity cost" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:main)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10",
          cost: "Infinity"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Cost must be a valid dollar amount/
    assert_select "input[name='entry[cost]'][value='Infinity']"
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

  test "does not create an entry for a home outside the current account" do
    sign_in_as users(:owner)

    assert_no_difference -> { Entry.count } do
      post home_entries_url(homes(:other)), params: {
        entry: {
          entry_type: "repair",
          title: "Fixed sink leak",
          occurred_on: "2026-07-10"
        }
      }
    end

    assert_response :not_found
  end

  test "shows an entry detail page" do
    sign_in_as users(:owner)
    entry = entries(:water_heater_replacement)

    get home_entry_url(homes(:main), entry)

    assert_response :success
    assert_select "a[href='#{home_path(homes(:main))}']", "Back to timeline"
    assert_select "h1", "Replaced water heater"
    assert_select "p", /Replacement/
    assert_select "p", /January 15, 2024/
    assert_select "a[href='#{home_item_path(homes(:main), items(:water_heater))}']", "Water Heater"
    assert_select "p", /Replaced the failing tank water heater./
    assert_select "p", /1,800.00/
    assert_select "p", /Reliable Plumbing/
  end

  test "shows entry attachments on the detail page" do
    sign_in_as users(:owner)
    entry = entries(:water_heater_replacement)
    entry.attachments.attach(
      io: File.open(Rails.root.join("test/fixtures/files/warranty.pdf")),
      filename: "warranty.pdf",
      content_type: "application/pdf"
    )

    get home_entry_url(homes(:main), entry)

    assert_response :success
    assert_select "h2", "Attachments"
    assert_select "a", "warranty.pdf"
  end

  test "shows an entry detail page without optional fields" do
    sign_in_as users(:owner)
    entry = entries(:move_in)

    get home_entry_url(homes(:main), entry)

    assert_response :success
    assert_select "h1", "Moved in"
    assert_select "a[href^='#{home_items_path(homes(:main))}/']", 0
    assert_select "p", text: /Cost/, count: 0
    assert_select "p", text: /Contractor or vendor/, count: 0
  end

  test "does not show an entry from another home" do
    sign_in_as users(:owner)
    second_home = accounts(:household).homes.create!(name: "Second Home")
    entry = second_home.entries.create!(
      entry_type: "note",
      title: "Second home note",
      occurred_on: Date.new(2026, 7, 12),
      created_by_user: users(:owner)
    )

    get home_entry_url(homes(:main), entry)

    assert_response :not_found
  end

  test "does not show an entry when the nested home is outside the current account" do
    sign_in_as users(:owner)

    get home_entry_url(homes(:other), entries(:water_heater_replacement))

    assert_response :not_found
  end
end
