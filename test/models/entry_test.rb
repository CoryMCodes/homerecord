require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "requires title" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
  end

  test "requires occurred on" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", title: "Replaced water heater")

    assert_not entry.valid?
    assert_includes entry.errors[:occurred_on], "can't be blank"
  end

  test "validates allowed entry type" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "reminder", title: "Change filter", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:entry_type], "is not included in the list"
  end

  test "requires creator" do
    entry = Entry.new(home: homes(:main), entry_type: "replacement", title: "Replaced water heater", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:created_by_user], "must exist"
  end

  test "allows blank item" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "memory", title: "Moved in", occurred_on: Date.current)

    assert entry.valid?
  end

  test "rejects item from another home" do
    entry = Entry.new(
      home: homes(:main),
      item: items(:other_water_heater),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )

    assert_not entry.valid?
    assert_includes entry.errors[:item], "must belong to the same home"
  end

  test "rejects unsaved item from another unsaved home" do
    account = Account.new(name: "Draft account")
    home = Home.new(account: account, name: "Draft home")
    other_home = Home.new(account: account, name: "Other draft home")
    item = Item.new(home: other_home, item_kind: "appliance", name: "Draft water heater")
    entry = Entry.new(
      home: home,
      item: item,
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )

    assert_not entry.valid?
    assert_includes entry.errors[:item], "must belong to the same home"
  end

  test "rejects negative cost" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "repair",
      title: "Garage door repair",
      occurred_on: Date.current,
      cost_cents: -1
    )

    assert_not entry.valid?
    assert_includes entry.errors[:cost_cents], "must be greater than or equal to 0"
  end

  test "rejects a cost above the database integer limit" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "repair",
      title: "Garage door repair",
      occurred_on: Date.current,
      cost_cents: Entry::MAX_COST_CENTS + 1
    )

    assert_not entry.valid?
    assert_includes entry.errors[:cost_cents], "must be less than or equal to #{Entry::MAX_COST_CENTS}"
  end

  test "allows up to ten supported attachments" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    10.times do |index|
      entry.attachments.attach(
        io: StringIO.new("pdf"),
        filename: "receipt-#{index}.pdf",
        content_type: "application/pdf"
      )
    end

    assert entry.valid?
  end

  test "rejects more than ten attachments" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    11.times do |index|
      entry.attachments.attach(
        io: StringIO.new("pdf"),
        filename: "receipt-#{index}.pdf",
        content_type: "application/pdf"
      )
    end

    assert_not entry.valid?
    assert_includes entry.errors[:attachments], "can include at most 10 files"
  end

  test "rejects unsupported attachment content type" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    entry.attachments.attach(
      io: StringIO.new("text"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    assert_not entry.valid?
    assert_includes entry.errors[:attachments], "must be a JPEG, PNG, HEIC, HEIF, or PDF"
  end

  test "allows iphone heic photos" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    entry.attachments.attach(
      io: StringIO.new("heic"),
      filename: "install-photo.heic",
      content_type: "image/heic"
    )

    assert entry.valid?
  end

  test "rejects supported content type with unsupported extension" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    entry.attachments.attach(
      io: StringIO.new("pdf"),
      filename: "warranty.txt",
      content_type: "application/pdf"
    )

    assert_not entry.valid?
    assert_includes entry.errors[:attachments], "must use a .jpg, .jpeg, .png, .heic, .heif, or .pdf extension"
  end

  test "rejects attachments larger than twenty megabytes" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )
    entry.attachments.attach(
      io: StringIO.new("x"),
      filename: "warranty.pdf",
      content_type: "application/pdf"
    )
    entry.attachments.first.blob.byte_size = 20.megabytes + 1

    assert_not entry.valid?
    assert_includes entry.errors[:attachments], "must be 20 MB or smaller"
  end
end
