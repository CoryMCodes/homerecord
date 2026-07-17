# Home-Scoped Entry Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let authenticated users create home-scoped timeline entries, optionally link entries to one of that home's items, redirect to entry detail, and see entries linked from the home timeline.

**Architecture:** Add a nested `EntriesController` under homes, mirroring the existing home-scoped item pattern. The controller owns entry creation, item scoping, dollar-to-cent cost normalization, and detail display; `homes#show` stays the timeline surface and links into entry creation/detail.

**Tech Stack:** Rails 8.1, ERB, Turbo-ready server-rendered views, PostgreSQL, Minitest integration tests.

## Global Constraints

- Entries must be nested under homes with `resources :entries, only: %i[new create show]`.
- Every entry action must load the home with `current_account.homes.find(params[:home_id])`.
- Entry params must not permit `home_id`, `created_by_user_id`, or raw `cost_cents`.
- Cost is entered in dollars and stored in `entries.cost_cents`.
- Item links are optional and must be limited to items belonging to the selected home.
- Successful entry creation redirects to `home_entry_path(@home, @entry)`.
- Attachments, attachment validations, editing entries, deleting entries, search, reminders, and polished mobile navigation are out of scope.

---

## File Structure

- Modify `config/routes.rb`: add nested home entry routes beside the existing nested item routes.
- Create `app/controllers/entries_controller.rb`: load the selected home, build/create/show entries, normalize cost dollars into cents, load home items for the form, and enforce item scoping.
- Create `app/views/entries/new.html.erb`: page wrapper for the entry form.
- Create `app/views/entries/_form.html.erb`: shared form markup and validation errors for new entry creation.
- Create `app/views/entries/show.html.erb`: entry detail page with optional item, description, cost, and contractor/vendor fields.
- Modify `app/views/homes/show.html.erb`: add Add entry link and link timeline titles to entry detail pages.
- Create `test/controllers/entries_controller_test.rb`: controller integration coverage for form display, creation, detail, validation, item scoping, and authorization.
- Modify `test/controllers/homes_controller_test.rb`: timeline link coverage for Add entry and entry detail links.

---

### Task 1: Routes And Timeline Links

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/views/homes/show.html.erb`
- Modify: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: existing `@timeline_entries` from `HomesController#show`.
- Produces: route helpers `new_home_entry_path(home)` and `home_entry_path(home, entry)` for later controller/view tests.

- [ ] **Step 1: Write failing timeline route/link tests**

Add these assertions to `test/controllers/homes_controller_test.rb`:

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: FAIL because `new_home_entry_path` or `home_entry_path` is not defined.

- [ ] **Step 3: Add nested entry routes**

Update `config/routes.rb` to:

```ruby
Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index new create show] do
    resources :items, only: %i[index new create show edit update]
    resources :entries, only: %i[new create show]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
```

- [ ] **Step 4: Update the timeline links**

Update `app/views/homes/show.html.erb` to:

```erb
<% content_for :title, @home.name %>

<section>
  <p><%= link_to "Homes", homes_path %></p>

  <h1><%= @home.name %></h1>

  <% if @home.address.present? %>
    <p><%= @home.address %></p>
  <% end %>

  <h2>Timeline</h2>

  <p><%= link_to "Add entry", new_home_entry_path(@home) %></p>

  <% if @timeline_entries.any? %>
    <ol>
      <% @timeline_entries.each do |entry| %>
        <li>
          <h3><%= link_to entry.title, home_entry_path(@home, entry) %></h3>
          <p><%= entry.occurred_on.to_fs(:long) %></p>

          <% if entry.description.present? %>
            <p><%= entry.description %></p>
          <% end %>
        </li>
      <% end %>
    </ol>
  <% else %>
    <p>No timeline entries yet.</p>
  <% end %>

  <nav aria-label="Home item actions">
    <%= link_to "View items", home_items_path(@home) %>
    <%= link_to "Add item", new_home_item_path(@home) %>
  </nav>
</section>
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/views/homes/show.html.erb test/controllers/homes_controller_test.rb
git commit -m "Add entry routes to timeline"
```

---

### Task 2: Entry Form Rendering

**Files:**
- Create: `app/controllers/entries_controller.rb`
- Create: `app/views/entries/new.html.erb`
- Create: `app/views/entries/_form.html.erb`
- Create: `test/controllers/entries_controller_test.rb`

**Interfaces:**
- Consumes: route helpers from Task 1 and existing `Entry::ENTRY_TYPES`.
- Produces: `EntriesController#new`, `@entry`, `@home`, `@items`, `@cost`, and an entry form posting to `home_entries_path(@home)`.

- [ ] **Step 1: Write failing form tests**

Create `test/controllers/entries_controller_test.rb` with:

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: FAIL because `EntriesController` is not defined.

- [ ] **Step 3: Add the minimal controller**

Create `app/controllers/entries_controller.rb`:

```ruby
class EntriesController < ApplicationController
  before_action :set_home
  before_action :set_items, only: %i[new create]

  def new
    @entry = @home.entries.build(occurred_on: Date.current)
    @cost = nil
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_items
    @items = @home.items.order(:name)
  end
end
```

- [ ] **Step 4: Add new page view**

Create `app/views/entries/new.html.erb`:

```erb
<% content_for :title, "Add entry" %>

<section>
  <p><%= link_to "Back to timeline", home_path(@home) %></p>

  <h1>Add entry</h1>

  <%= render "form", home: @home, entry: @entry, items: @items, cost: @cost, submit_label: "Create entry" %>
</section>
```

- [ ] **Step 5: Add entry form partial**

Create `app/views/entries/_form.html.erb`:

```erb
<% if entry.errors.any? %>
  <div role="alert">
    <p>Please check the entry details.</p>

    <ul>
      <% entry.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<%= form_with model: [ home, entry ] do |form| %>
  <div>
    <%= form.label :entry_type, "Entry type" %>
    <%= form.select :entry_type, options_for_select(Entry::ENTRY_TYPES.map { |entry_type| [ entry_type.humanize, entry_type ] }, entry.entry_type), include_blank: true, required: true %>
  </div>

  <div>
    <%= form.label :title %>
    <%= form.text_field :title, required: true, autofocus: true %>
  </div>

  <div>
    <%= form.label :occurred_on, "Occurred on" %>
    <%= form.date_field :occurred_on, required: true %>
  </div>

  <div>
    <%= form.label :item_id, "Item" %>
    <%= form.select :item_id, options_from_collection_for_select(items, :id, :name, entry.item_id), include_blank: "No item" %>
  </div>

  <div>
    <%= form.label :description %>
    <%= form.text_area :description, rows: 4 %>
  </div>

  <div>
    <%= form.label :cost, "Cost" %>
    <%= form.text_field :cost, value: cost, inputmode: "decimal" %>
  </div>

  <div>
    <%= form.label :contractor_name, "Contractor or vendor" %>
    <%= form.text_field :contractor_name %>
  </div>

  <%= form.submit submit_label %>
<% end %>
```

- [ ] **Step 6: Run tests to verify they pass**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/entries_controller.rb app/views/entries/new.html.erb app/views/entries/_form.html.erb test/controllers/entries_controller_test.rb
git commit -m "Add entry creation form"
```

---

### Task 3: Entry Creation And Cost Normalization

**Files:**
- Modify: `app/controllers/entries_controller.rb`
- Modify: `test/controllers/entries_controller_test.rb`

**Interfaces:**
- Consumes: `EntriesController#new` and `@items` from Task 2.
- Produces: `EntriesController#create`, private `entry_params`, private `assign_item`, private `assign_cost`, private `formatted_cost`, private `normalized_cost_cents`, and redirects to `home_entry_path(@home, @entry)`.

- [ ] **Step 1: Add failing creation tests**

Append these tests inside `EntriesControllerTest`:

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: FAIL because `EntriesController#create` is missing.

- [ ] **Step 3: Implement create, item scoping, and cost normalization**

Update `app/controllers/entries_controller.rb` to:

```ruby
class EntriesController < ApplicationController
  before_action :set_home
  before_action :set_items, only: %i[new create]

  def new
    @entry = @home.entries.build(occurred_on: Date.current)
    @cost = nil
  end

  def create
    @entry = @home.entries.build(entry_params)
    @entry.created_by_user = Current.user
    @cost = submitted_cost.presence
    assign_item
    assign_cost

    if @entry.errors.empty? && @entry.save
      redirect_to home_entry_path(@home, @entry)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_items
    @items = @home.items.order(:name)
  end

  def entry_params
    params.require(:entry).permit(:entry_type, :title, :occurred_on, :description, :contractor_name)
  end

  def submitted_item_id
    params.dig(:entry, :item_id).presence
  end

  def assign_item
    return if submitted_item_id.blank?

    @entry.item = @home.items.find_by(id: submitted_item_id)
    @entry.errors.add(:item, "must belong to this home") if @entry.item.blank?
  end

  def submitted_cost
    params.dig(:entry, :cost).to_s.strip
  end

  def assign_cost
    return if submitted_cost.blank?

    @entry.cost_cents = normalized_cost_cents
    @cost = formatted_cost
  rescue ArgumentError
    @entry.errors.add(:cost, "must be a valid dollar amount")
  end

  def formatted_cost
    format("%.2f", @entry.cost_cents / 100.0)
  end

  def normalized_cost_cents
    dollars = BigDecimal(submitted_cost)
    raise ArgumentError if dollars.negative?

    (dollars * 100).round.to_i
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/entries_controller.rb test/controllers/entries_controller_test.rb
git commit -m "Create home timeline entries"
```

---

### Task 4: Entry Detail Page And Authorization

**Files:**
- Modify: `app/controllers/entries_controller.rb`
- Create: `app/views/entries/show.html.erb`
- Modify: `test/controllers/entries_controller_test.rb`

**Interfaces:**
- Consumes: redirect target from Task 3 and existing item detail route `home_item_path(home, item)`.
- Produces: `EntriesController#show` and full entry detail rendering for successful create redirects.

- [ ] **Step 1: Add failing detail and authorization tests**

Append these tests inside `EntriesControllerTest`:

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: FAIL because `EntriesController#show` and `app/views/entries/show.html.erb` are missing.

- [ ] **Step 3: Add show action and entry loader**

Update `app/controllers/entries_controller.rb` to:

```ruby
class EntriesController < ApplicationController
  before_action :set_home
  before_action :set_entry, only: %i[show]
  before_action :set_items, only: %i[new create]

  def new
    @entry = @home.entries.build(occurred_on: Date.current)
    @cost = nil
  end

  def create
    @entry = @home.entries.build(entry_params)
    @entry.created_by_user = Current.user
    @cost = submitted_cost.presence
    assign_item
    assign_cost

    if @entry.errors.empty? && @entry.save
      redirect_to home_entry_path(@home, @entry)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_entry
    @entry = @home.entries.find(params[:id])
  end

  def set_items
    @items = @home.items.order(:name)
  end

  def entry_params
    params.require(:entry).permit(:entry_type, :title, :occurred_on, :description, :contractor_name)
  end

  def submitted_item_id
    params.dig(:entry, :item_id).presence
  end

  def assign_item
    return if submitted_item_id.blank?

    @entry.item = @home.items.find_by(id: submitted_item_id)
    @entry.errors.add(:item, "must belong to this home") if @entry.item.blank?
  end

  def submitted_cost
    params.dig(:entry, :cost).to_s.strip
  end

  def assign_cost
    return if submitted_cost.blank?

    @entry.cost_cents = normalized_cost_cents
    @cost = formatted_cost
  rescue ArgumentError
    @entry.errors.add(:cost, "must be a valid dollar amount")
  end

  def formatted_cost
    format("%.2f", @entry.cost_cents / 100.0)
  end

  def normalized_cost_cents
    dollars = BigDecimal(submitted_cost)
    raise ArgumentError if dollars.negative?

    (dollars * 100).round.to_i
  end
end
```

- [ ] **Step 4: Add detail view**

Create `app/views/entries/show.html.erb`:

```erb
<% content_for :title, @entry.title %>

<section>
  <p><%= link_to "Back to timeline", home_path(@home) %></p>

  <h1><%= @entry.title %></h1>

  <p><%= @entry.entry_type.humanize %></p>
  <p><%= @entry.occurred_on.to_fs(:long) %></p>

  <% if @entry.item.present? %>
    <p>
      Item:
      <%= link_to @entry.item.name, home_item_path(@home, @entry.item) %>
    </p>
  <% end %>

  <% if @entry.description.present? %>
    <p><%= @entry.description %></p>
  <% end %>

  <% if @entry.cost_cents.present? %>
    <p>Cost: <%= number_to_currency(@entry.cost_cents / 100.0) %></p>
  <% end %>

  <% if @entry.contractor_name.present? %>
    <p>Contractor or vendor: <%= @entry.contractor_name %></p>
  <% end %>
</section>
```

- [ ] **Step 5: Run entry tests to verify they pass**

Run:

```bash
bin/rails test test/controllers/entries_controller_test.rb
```

Expected: PASS.

- [ ] **Step 6: Run combined controller tests**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb test/controllers/entries_controller_test.rb
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/entries_controller.rb app/views/entries/show.html.erb test/controllers/entries_controller_test.rb
git commit -m "Show entry details"
```

---

### Task 5: Full Verification

**Files:**
- No code files should change in this task.

**Interfaces:**
- Consumes: all implementation from Tasks 1-4.
- Produces: verified entry creation slice with passing Rails test suite.

- [ ] **Step 1: Run the full Rails test suite**

Run:

```bash
bin/rails test
```

Expected: PASS.

- [ ] **Step 2: Run RuboCop**

Run:

```bash
bin/rubocop
```

Expected: no offenses.

- [ ] **Step 3: Inspect final diff**

Run:

```bash
git status --short
git diff --stat
```

Expected: only files intentionally changed by Tasks 1-4 appear before the final commit, and no unrelated files appear.

- [ ] **Step 4: Commit verification fixes if any were needed**

If Step 1 or Step 2 required code fixes, commit only those fixes:

```bash
git add app/controllers/entries_controller.rb app/views/entries app/views/homes/show.html.erb config/routes.rb test/controllers/entries_controller_test.rb test/controllers/homes_controller_test.rb
git commit -m "Polish entry creation slice"
```

If no fixes were needed, do not create an empty commit.
