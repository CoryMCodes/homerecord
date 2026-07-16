# Home-Scoped Items Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let authenticated users create, browse, view, and Turbo-edit systems and appliances scoped to a selected home.

**Architecture:** Add a nested `ItemsController` under homes. Every item action loads the home through `current_account.homes.find(params[:home_id])`, then builds or finds items through that home. Keep `homes#show` as the timeline and link to item browsing and creation from the bottom of that page.

**Tech Stack:** Ruby 3.4+, Rails 8.1, ERB, Turbo, Importmap, Minitest, Rails fixtures.

## Global Constraints

- `homes#show` remains the selected home's timeline.
- Routes must nest items under homes with `resources :items, only: %i[index new create show edit update]`.
- `ItemsController` must load homes with `current_account.homes.find(params[:home_id])`.
- Member item actions must load items with `@home.items.find(params[:id])`.
- Item params must not permit `home_id`.
- Item kinds must come from `Item::ITEM_KINDS`.
- Item fields are `item_kind`, `name`, `brand`, `model_number`, `serial_number`, `installed_on`, and `notes`.
- Successful item creation redirects to `home_item_path(@home, @item)`.
- Invalid item creation renders `items/new` with `422 Unprocessable Entity`.
- Item edit happens from `items#show` through a stable Turbo Frame.
- Successful item update redirects to `home_item_path(@home, @item)` with `303 See Other`.
- Invalid item update re-renders `items/edit` with `422 Unprocessable Entity`.
- Out of scope: item deletion, item-linked entry creation, attachments, search, rooms, global item index, inline editing from `items#index`, bottom dock navigation, polished mobile visual design, and Hotwire Native behavior.

---

## File Structure

- Modify: `config/routes.rb`
  - Nest item routes under homes.
- Create: `app/controllers/items_controller.rb`
  - Own home-scoped item index, creation, detail, edit, and update.
- Modify: `app/views/homes/show.html.erb`
  - Add bottom-of-timeline links to the selected home's items and new item form.
- Create: `app/views/items/index.html.erb`
  - List one home's systems and appliances.
- Create: `app/views/items/new.html.erb`
  - Render the item creation form.
- Create: `app/views/items/show.html.erb`
  - Render item detail inside a stable Turbo Frame.
- Create: `app/views/items/edit.html.erb`
  - Render the edit form inside the same Turbo Frame.
- Create: `app/views/items/_form.html.erb`
  - Share item form fields for new and edit views.
- Create: `app/views/items/_item_details.html.erb`
  - Render item details for `items#show`.
- Create: `test/controllers/items_controller_test.rb`
  - Cover nested routing, listing, creation, detail, Turbo edit, update, validation, and authorization boundaries.
- Modify: `test/controllers/homes_controller_test.rb`
  - Cover the new timeline links.

---

### Task 1: Home-Scoped Item Listing And Creation

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/items_controller.rb`
- Modify: `app/views/homes/show.html.erb`
- Create: `app/views/items/index.html.erb`
- Create: `app/views/items/new.html.erb`
- Create: `app/views/items/_form.html.erb`
- Create: `test/controllers/items_controller_test.rb`
- Modify: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: `current_account` from `ApplicationController`, `Item::ITEM_KINDS`, `sign_in_as(user)` from `test/test_helpers/session_test_helper.rb`, existing fixtures `users(:owner)`, `homes(:main)`, `homes(:other)`, `items(:water_heater)`, and `items(:other_water_heater)`.
- Produces: nested route helpers `home_items_path(home)`, `new_home_item_path(home)`, and `home_item_path(home, item)`; `ItemsController#index`, `ItemsController#new`, and `ItemsController#create`; private `ItemsController#item_params` permitting `:item_kind`, `:name`, `:brand`, `:model_number`, `:serial_number`, `:installed_on`, and `:notes`.

- [ ] **Step 1: Write failing tests for listing, creation, and timeline links**

Create `test/controllers/items_controller_test.rb` with:

```ruby
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
end
```

Modify `test/controllers/homes_controller_test.rb` by adding this test before the final `end`:

```ruby
  test "timeline links to home scoped items" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "a[href='#{home_items_path(homes(:main))}']", "View items"
    assert_select "a[href='#{new_home_item_path(homes(:main))}']", "Add item"
  end
```

- [ ] **Step 2: Run the focused tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/items_controller_test.rb test/controllers/homes_controller_test.rb
```

Expected: FAIL with missing nested route helpers such as `home_items_url` or `new_home_item_path`.

- [ ] **Step 3: Add nested item routes**

Replace `config/routes.rb` with:

```ruby
Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index new create show] do
    resources :items, only: %i[index new create show edit update]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
```

- [ ] **Step 4: Create the items controller for listing and creation**

Create `app/controllers/items_controller.rb` with:

```ruby
class ItemsController < ApplicationController
  before_action :set_home

  def index
    @items = @home.items.order(:name)
  end

  def new
    @item = @home.items.build
  end

  def create
    @item = @home.items.build(item_params)

    if @item.save
      redirect_to home_item_path(@home, @item)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def item_params
    params.require(:item).permit(:item_kind, :name, :brand, :model_number, :serial_number, :installed_on, :notes)
  end
end
```

- [ ] **Step 5: Add bottom-of-timeline item links**

Replace `app/views/homes/show.html.erb` with:

```erb
<% content_for :title, @home.name %>

<section>
  <p><%= link_to "Homes", homes_path %></p>

  <h1><%= @home.name %></h1>

  <% if @home.address.present? %>
    <p><%= @home.address %></p>
  <% end %>

  <h2>Timeline</h2>

  <% if @timeline_entries.any? %>
    <ol>
      <% @timeline_entries.each do |entry| %>
        <li>
          <h3><%= entry.title %></h3>
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

- [ ] **Step 6: Create the shared item form partial**

Create `app/views/items/_form.html.erb` with:

```erb
<% if item.errors.any? %>
  <div role="alert">
    <p>Please check the item details.</p>

    <ul>
      <% item.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<%= form_with model: [ home, item ] do |form| %>
  <div>
    <%= form.label :item_kind, "Item kind" %>
    <%= form.select :item_kind, options_for_select(Item::ITEM_KINDS.map { |item_kind| [ item_kind.humanize, item_kind ] }, item.item_kind), include_blank: true, required: true %>
  </div>

  <div>
    <%= form.label :name %>
    <%= form.text_field :name, required: true, autofocus: true %>
  </div>

  <div>
    <%= form.label :brand %>
    <%= form.text_field :brand %>
  </div>

  <div>
    <%= form.label :model_number, "Model number" %>
    <%= form.text_field :model_number %>
  </div>

  <div>
    <%= form.label :serial_number, "Serial number" %>
    <%= form.text_field :serial_number %>
  </div>

  <div>
    <%= form.label :installed_on, "Installed on" %>
    <%= form.date_field :installed_on %>
  </div>

  <div>
    <%= form.label :notes %>
    <%= form.text_area :notes, rows: 4 %>
  </div>

  <%= form.submit submit_label %>
<% end %>
```

- [ ] **Step 7: Create the item index view**

Create `app/views/items/index.html.erb` with:

```erb
<% content_for :title, "Items for #{@home.name}" %>

<section>
  <p><%= link_to "Back to timeline", home_path(@home) %></p>

  <h1>Items for <%= @home.name %></h1>

  <p><%= link_to "Add item", new_home_item_path(@home) %></p>

  <% if @items.any? %>
    <ul>
      <% @items.each do |item| %>
        <li>
          <h2><%= link_to item.name, home_item_path(@home, item) %></h2>
          <p><%= item.item_kind.humanize %></p>

          <% if item.brand.present? || item.model_number.present? || item.serial_number.present? %>
            <p>
              <%= [ item.brand, item.model_number, item.serial_number ].compact_blank.join(" - ") %>
            </p>
          <% end %>
        </li>
      <% end %>
    </ul>
  <% else %>
    <p>No systems or appliances yet.</p>
  <% end %>
</section>
```

- [ ] **Step 8: Create the new item view**

Create `app/views/items/new.html.erb` with:

```erb
<% content_for :title, "Add item" %>

<section>
  <p><%= link_to "Back to items", home_items_path(@home) %></p>

  <h1>Add item</h1>

  <%= render "form", home: @home, item: @item, submit_label: "Create item" %>
</section>
```

- [ ] **Step 9: Run the focused tests**

Run:

```bash
bin/rails test test/controllers/items_controller_test.rb test/controllers/homes_controller_test.rb
```

Expected: PASS for the listing, new form, creation redirect, validation failure, authorization, and timeline link assertions. Item show content is covered in Task 2.

- [ ] **Step 10: Commit the listing and creation slice**

Run:

```bash
git add config/routes.rb app/controllers/items_controller.rb app/views/homes/show.html.erb app/views/items/index.html.erb app/views/items/new.html.erb app/views/items/_form.html.erb test/controllers/items_controller_test.rb test/controllers/homes_controller_test.rb
git commit -m "Add home scoped item creation"
```

Expected: commit succeeds.

---

### Task 2: Item Detail And Turbo-Frame Editing

**Files:**
- Modify: `app/controllers/items_controller.rb`
- Create: `app/views/items/show.html.erb`
- Create: `app/views/items/edit.html.erb`
- Create: `app/views/items/_item_details.html.erb`
- Modify: `test/controllers/items_controller_test.rb`

**Interfaces:**
- Consumes: `@home` from `ItemsController#set_home`, nested route helpers, `ActionView::RecordIdentifier#dom_id` in Rails views, and the `_form` partial from Task 1.
- Produces: `ItemsController#show`, `ItemsController#edit`, `ItemsController#update`, private `ItemsController#set_item`, item detail Turbo Frame id `dom_id(@item)`, and an edit form that posts `PATCH /homes/:home_id/items/:id`.

- [ ] **Step 1: Add failing tests for show, edit, update, and authorization boundaries**

Append these tests inside `test/controllers/items_controller_test.rb` before the final `end`:

```ruby
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
```

- [ ] **Step 2: Run focused tests to verify they fail**

Run:

```bash
bin/rails test test/controllers/items_controller_test.rb
```

Expected: FAIL with missing `ItemsController#show`, `ItemsController#edit`, `ItemsController#update`, or missing item views.

- [ ] **Step 3: Add show, edit, update, and item loading to the controller**

Replace `app/controllers/items_controller.rb` with:

```ruby
class ItemsController < ApplicationController
  before_action :set_home
  before_action :set_item, only: %i[show edit update]

  def index
    @items = @home.items.order(:name)
  end

  def new
    @item = @home.items.build
  end

  def create
    @item = @home.items.build(item_params)

    if @item.save
      redirect_to home_item_path(@home, @item)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to home_item_path(@home, @item), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_home
    @home = current_account.homes.find(params[:home_id])
  end

  def set_item
    @item = @home.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:item_kind, :name, :brand, :model_number, :serial_number, :installed_on, :notes)
  end
end
```

- [ ] **Step 4: Create the item detail partial**

Create `app/views/items/_item_details.html.erb` with:

```erb
<h1><%= item.name %></h1>

<p><%= item.item_kind.humanize %></p>

<% if item.brand.present? %>
  <p>Brand: <%= item.brand %></p>
<% end %>

<% if item.model_number.present? %>
  <p>Model number: <%= item.model_number %></p>
<% end %>

<% if item.serial_number.present? %>
  <p>Serial number: <%= item.serial_number %></p>
<% end %>

<% if item.installed_on.present? %>
  <p>Installed on: <%= item.installed_on.to_fs(:long) %></p>
<% end %>

<% if item.notes.present? %>
  <p><%= item.notes %></p>
<% end %>

<p><%= link_to "Edit", edit_home_item_path(home, item), data: { turbo_frame: dom_id(item) } %></p>
```

- [ ] **Step 5: Create the item show view with a stable Turbo Frame**

Create `app/views/items/show.html.erb` with:

```erb
<% content_for :title, @item.name %>

<section>
  <p><%= link_to "Back to items", home_items_path(@home) %></p>

  <%= turbo_frame_tag dom_id(@item) do %>
    <%= render "item_details", home: @home, item: @item %>
  <% end %>
</section>
```

- [ ] **Step 6: Create the Turbo-frame edit view**

Create `app/views/items/edit.html.erb` with:

```erb
<% content_for :title, "Edit #{@item.name}" %>

<%= turbo_frame_tag dom_id(@item) do %>
  <h1>Edit <%= @item.name %></h1>

  <%= render "form", home: @home, item: @item, submit_label: "Save item" %>

  <p><%= link_to "Cancel", home_item_path(@home, @item) %></p>
<% end %>
```

- [ ] **Step 7: Run the focused item controller tests**

Run:

```bash
bin/rails test test/controllers/items_controller_test.rb
```

Expected: PASS.

- [ ] **Step 8: Run the homes controller tests**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: PASS.

- [ ] **Step 9: Commit the detail and Turbo edit slice**

Run:

```bash
git add app/controllers/items_controller.rb app/views/items/show.html.erb app/views/items/edit.html.erb app/views/items/_item_details.html.erb test/controllers/items_controller_test.rb
git commit -m "Add item detail and turbo editing"
```

Expected: commit succeeds.

---

### Task 3: Full Verification

**Files:**
- Read: `docs/superpowers/specs/2026-07-15-home-scoped-items-design.md`
- Verify: `config/routes.rb`
- Verify: `app/controllers/items_controller.rb`
- Verify: `app/views/homes/show.html.erb`
- Verify: `app/views/items/index.html.erb`
- Verify: `app/views/items/new.html.erb`
- Verify: `app/views/items/show.html.erb`
- Verify: `app/views/items/edit.html.erb`
- Verify: `app/views/items/_form.html.erb`
- Verify: `app/views/items/_item_details.html.erb`
- Verify: `test/controllers/items_controller_test.rb`
- Verify: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: Completed Tasks 1 and 2.
- Produces: A verified working tree with tests passing for the home-scoped item slice.

- [ ] **Step 1: Review routes for the expected nested helpers**

Run:

```bash
bin/rails routes -g item
```

Expected output includes these route names and paths:

```text
home_items GET    /homes/:home_id/items(.:format)          items#index
           POST   /homes/:home_id/items(.:format)          items#create
new_home_item GET /homes/:home_id/items/new(.:format)      items#new
edit_home_item GET /homes/:home_id/items/:id/edit(.:format) items#edit
home_item GET    /homes/:home_id/items/:id(.:format)       items#show
          PATCH  /homes/:home_id/items/:id(.:format)       items#update
```

- [ ] **Step 2: Run the focused controller tests**

Run:

```bash
bin/rails test test/controllers/items_controller_test.rb test/controllers/homes_controller_test.rb
```

Expected: PASS.

- [ ] **Step 3: Run the full Rails test suite**

Run:

```bash
bin/rails test
```

Expected: PASS.

- [ ] **Step 4: Run RuboCop**

Run:

```bash
bin/rubocop
```

Expected: no offenses.

- [ ] **Step 5: Check the working tree**

Run:

```bash
git status --short
```

Expected: no unstaged or uncommitted changes if Tasks 1 and 2 were committed. If verification-only changes are present, inspect them and commit only intentional fixes with:

```bash
git add path/to/intentional-file
git commit -m "Fix home scoped item verification findings"
```
